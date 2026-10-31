data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}




# Application Load Balancer (internet-facing)
#####################################################
resource "aws_lb" "app" {
  name               = "app-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.public_sg.id]
  subnets            = [aws_subnet.public.id, aws_subnet.public_2.id]

  tags = {
    Name = "app-alb-1"
  }

  depends_on = [aws_internet_gateway.igw]
}
##########################################################################
# Instance 1 – Application Server
#####################################
- Host the web application.
- Install and configure Nginx through Ansible.
- Run the application and expose its required internal application port.
- Configure Nginx as a Reverse Proxy.
#Place the instance in the Public Subnet.

resource "aws_instance" "app" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.public.id

  vpc_security_group_ids      = [aws_security_group.app_sg.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  tags = {
    Name = "app-instance-1"
  }
}

########################################################################
Instance 2 – MariaDB Server
############################
# Host the MariaDB relational database.
# Accept database connections only from authorized application instances.
# Place the instance in the Private Subnet.

resource "aws_instance" "db" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  key_name               = var.key_name
  tags = {
    Name = "db-instance-1"
  }
}
########################################################################
Instance 3 – RabbitMQ Server
#############################
# Host the RabbitMQ message broker.
# Enable asynchronous communication between application components.
# Restrict message broker access to authorized application instances.
# Place the instance in the Private Subnet.

resource "aws_instance" "mq" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.rabbitmq_sg.id]
  tags = {
    Name = "mq-instance-1"
  }
}

########################################################################
Instance 4 – Memcached Server
#############################
# Host the Memcached caching service.
# Provide in-memory caching to improve application performance.
# Restrict cache access to authorized application instances.
# Place the instance in the Private Subnet.
resource "aws_instance" "mem" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.memcached_sg.id]
  tags = {
    Name = "mem-instance-1"
  }
}