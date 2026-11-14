data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 key pairs store public keys only. SSH provisioners below read local private keys.
resource "aws_key_pair" "admin" {
  key_name   = "vprofile-admin"
  public_key = file("${path.module}/keys/admin.pub")
}
resource "aws_key_pair" "managed" {
  key_name   = "vprofile-managed"
  public_key = file("${path.module}/keys/managed.pub")
}



# Application Load Balancer (internet-facing)
#####################################################
resource "aws_lb" "app" {
  name               = "app-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.public_sg.id]
  subnets            = [aws_subnet.public.id, aws_subnet.public_2.id]
  drop_invalid_header_fields = true
  tags = {
    Name = "app-alb-1"
  }

  depends_on = [aws_internet_gateway.igw]
}
##########################################################################
# Instance 1 – Application Server
#####################################
# Host the web application.
# Install and configure Nginx through Ansible.
# Run the application and expose its required internal application port.
# Configure Nginx as a Reverse Proxy.
# Place the instance in the Public Subnet.

resource "aws_instance" "app" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.public.id
  key_name      = aws_key_pair.admin.key_name
  vpc_security_group_ids      = [aws_security_group.app_sg.id]
  associate_public_ip_address = true
  metadata_options {
    http_tokens = "required"
  }
  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }
  lifecycle {
    ignore_changes = [ami]
  }
  tags = {
    Name = "app-instance-1"
  }
}

########################################################################
#Instance 2 – MariaDB Server
############################
# Host the MariaDB relational database.
# Accept database connections only from authorized application instances.
# Place the instance in the Private Subnet.

resource "aws_instance" "db" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.private.id
  key_name      = aws_key_pair.managed.key_name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  metadata_options {
    http_tokens = "required"
  }
  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }
  lifecycle {
    ignore_changes = [ami]
  }
  tags = {
    Name = "db-instance-1"
  }
}
########################################################################
#Instance 3 – RabbitMQ Server
#############################
# Host the RabbitMQ message broker.
# Enable asynchronous communication between application components.
# Restrict message broker access to authorized application instances.
# Place the instance in the Private Subnet.

resource "aws_instance" "mq" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.private.id
  key_name      = aws_key_pair.managed.key_name
  vpc_security_group_ids = [aws_security_group.rabbitmq_sg.id]
  metadata_options {
    http_tokens = "required"
  }
  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }
  lifecycle {
    ignore_changes = [ami]
  }
  tags = {
    Name = "mq-instance-1"
  }
}

########################################################################
#Instance 4 – Memcached Server
#############################
# Host the Memcached caching service.
# Provide in-memory caching to improve application performance.
# Restrict cache access to authorized application instances.
# Place the instance in the Private Subnet.
resource "aws_instance" "mem" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.private.id
  key_name      = aws_key_pair.managed.key_name
  vpc_security_group_ids = [aws_security_group.memcached_sg.id]
  metadata_options {
    http_tokens = "required"
  }
  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }
  lifecycle {
    ignore_changes = [ami]
  }
  tags = {
    Name = "mem-instance-1"
  }
}

#####################################################################
# Configure Ansible (Generate the Ansible inventory locally on apply)
#####################################################################
resource "local_file" "ansible_inventory" {
  filename        = "${path.module}/../ansible/inventory.ini"
  file_permission = "0644"
  content         = <<-EOT
    [app]
    ${aws_instance.app.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=keys/admin.pem

    [mariadb]
    ${aws_instance.db.private_ip} ansible_user=ubuntu ansible_ssh_private_key_file=keys/managed.pem

    [rabbitmq]
    ${aws_instance.mq.private_ip} ansible_user=ubuntu ansible_ssh_private_key_file=keys/managed.pem

    [memcached]
    ${aws_instance.mem.private_ip} ansible_user=ubuntu ansible_ssh_private_key_file=keys/managed.pem
  EOT
}


