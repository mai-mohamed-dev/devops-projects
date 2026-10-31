# Create a custom AWS Virtual Private Cloud (VPC) with CIDR block "10.0.0.0/16".
###############################################################################
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "main-vpc-1"
  }
  enable_dns_support   = true
  enable_dns_hostnames = true 
}

# Create a Public Subnet with CIDR block "10.0.1.0/24".
#######################################################
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_cidr
  availability_zone       = var.av_zone
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-1"
  }
   depends_on = [aws_vpc.main]
}
resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_cidr_2
  availability_zone       = var.av_zone_2
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-2"
  }
   depends_on = [aws_vpc.main]
}

# Create a Private Subnet with CIDR block "10.0.2.0/24".
########################################################
resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_cidr
  availability_zone       = var.av_zone
  tags = {
    Name = "private-subnet-1"
  }
  depends_on = [aws_vpc.main]
}

# Provision and attach an Internet Gateway (IGW) to the VPC.
##############################################################
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-igw-1"
  }
  depends_on = [aws_vpc.main]
}

# Configure public and private Route Tables with appropriate routing rules.
############################################################################
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "public-rtable-1"
  }
  depends_on = [aws_vpc.main, aws_internet_gateway.igw]
}
resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
   }
  tags = {
    Name = "private-rtable-1"
  }
  depends_on = [aws_vpc.main]
}

# Link each route table to its subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# Configure outbound internet access for private instances through a NAT Gateway or
# an approved alternative when required for software installation and updates.
###########################################################################################
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "nat-gateway-eip"
  }
  depends_on = [aws_internet_gateway.igw]
}
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
  tags = {
    Name = "main-nat-1"
  }
  depends_on = [aws_internet_gateway.igw]
}
################################################################################################################
# Load Balancer Public Security Group
########################################
resource "aws_security_group" "public_sg" {
  name        = "public-tier-sg"
  description = "Security group for public load balancer"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "public-sg-1"
  }
}

# Ingress Rule: Allow HTTP from the internet
resource "aws_vpc_security_group_ingress_rule" "public_http" {
  security_group_id = aws_security_group.public_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = var.app_port
  ip_protocol       = "tcp"
  to_port           = var.app_port
}

# Ingress Rule: Allow HTTPS from the internet
resource "aws_vpc_security_group_ingress_rule" "public_https" {
  security_group_id = aws_security_group.public_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

# Egress Rule: Allow all outbound traffic
resource "aws_vpc_security_group_egress_rule" "public_outbound" {
  security_group_id = aws_security_group.public_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

#--------------------------------------------
# Application Security Group
#############################
resource "aws_security_group" "app_sg" {
  name        = "app-tier-sg"
  description = "Security group for internal application components"
  vpc_id      = aws_vpc.main.id
  tags = {
    Name = "app-sg-1"
  }
  depends_on = [aws_vpc.main]
}

# Allow HTTP traffic on port 80 from the Application Load Balancer.
resource "aws_vpc_security_group_ingress_rule" "app_sg_rule" {
  description     = "Allow app traffic from ALB"
  security_group_id = aws_security_group.app_sg.id
  referenced_security_group_id = aws_security_group.public_sg.id 
  from_port   = var.app_port
  ip_protocol = "tcp"
  to_port     = var.app_port
}

# Allow application-related internal traffic where required.
resource "aws_vpc_security_group_ingress_rule" "app_sg_rule2" {
  description = "Allow internal app communication"
  security_group_id = aws_security_group.app_sg.id
  referenced_security_group_id = aws_security_group.app_sg.id 
  from_port   = 8080
  ip_protocol = "tcp"
  to_port     = 8080
}

#Allow all outbound traffic (for patches and updates via NAT Gateway)
resource "aws_vpc_security_group_egress_rule" "app_out_rule" {
  security_group_id = aws_security_group.app_sg.id
  description = "Allow all outbound traffic"
  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}
#--------------------------------------------

# MariaDB Security Group
#############################
resource "aws_security_group" "db_sg" {
  name        = "db-tier-sg"
  description = "Security group for MariaDB database tier"
  vpc_id      = aws_vpc.main.id
  tags = {
    Name = "db-sg-1"
  }
}

# Allow TCP port 3306 only from the Application Server Security Group.
resource "aws_vpc_security_group_ingress_rule" "db_ingress_mysql" {
  description                  = "Allow MySQL/MariaDB from Application SG"
  security_group_id            = aws_security_group.db_sg.id
  referenced_security_group_id = aws_security_group.app_sg.id
  from_port                    = 3306
  ip_protocol                  = "tcp"
  to_port                      = 3306
}

# Egress Rule: Allow outbound traffic (or you can restrict this depending on your patch management strategy)
resource "aws_vpc_security_group_egress_rule" "db_outbound" {
  security_group_id = aws_security_group.db_sg.id
  description       = "Allow all outbound traffic"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
#------------------------------------------------------------------
# RabbitMQ Security Group
#############################
resource "aws_security_group" "rabbitmq_sg" {
  name        = "rabbitmq-tier-sg"
  description = "Security group for RabbitMQ message broker tier"
  vpc_id      = aws_vpc.main.id
  tags = {
    Name = "rabbitmq-sg-1"
  }
}

# Allow TCP port 5672 only from the Application Server Security Group.
resource "aws_vpc_security_group_ingress_rule" "rabbitmq_ingress_amqp" {
  description                  = "Allow AMQP (5672) from Application SG"
  security_group_id            = aws_security_group.rabbitmq_sg.id
  referenced_security_group_id = aws_security_group.app_sg.id
  from_port                    = 5672
  ip_protocol                  = "tcp"
  to_port                      = 5672
}

# Restrict RabbitMQ management interface access:
# Port 15672 for the management UI is intentionally omitted from public access. 

# Egress Rule: Allow all outbound traffic (for patches and updates via NAT Gateway)
resource "aws_vpc_security_group_egress_rule" "rabbitmq_outbound" {
  security_group_id = aws_security_group.rabbitmq_sg.id
  description       = "Allow all outbound traffic"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

#--------------------------------------------
# Memcached Security Group
#############################
resource "aws_security_group" "memcached_sg" {
  name        = "memcached-tier-sg"
  description = "Security group for Memcached caching tier"
  vpc_id      = aws_vpc.main.id
  tags = {
    Name = "memcached-sg-1"
  }
}

# Allow TCP port 11211 only from the Application Server Security Group.
resource "aws_vpc_security_group_ingress_rule" "memcached_ingress" {
  description                  = "Allow Memcached from Application SG"
  security_group_id            = aws_security_group.memcached_sg.id
  referenced_security_group_id = aws_security_group.app_sg.id
  from_port                    = 11211
  ip_protocol                  = "tcp"
  to_port                      = 11211
}

# Egress Rule: Allow all outbound traffic (for patches and updates via NAT Gateway)
resource "aws_vpc_security_group_egress_rule" "memcached_outbound" {
  security_group_id = aws_security_group.memcached_sg.id
  description       = "Allow all outbound traffic"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_lb_target_group" "app" {
  name                 = "app-tg"
  port                 = var.app_port
  protocol             = "HTTP"
  target_type          = "instance"
  vpc_id               = aws_vpc.main.id
  deregistration_delay = 30
  health_check {
    enabled             = true
    path                = "/"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
  tags = {
    Name = "app-tg-1"
  }
}

resource "aws_lb_target_group_attachment" "app" {
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.app.id 
  port             = var.app_port
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = var.app_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}


# SSH to the app instance from your IP only (it is also the jump host)
resource "aws_vpc_security_group_ingress_rule" "app_ssh_admin" {
  description       = "SSH from admin IP"
  security_group_id = aws_security_group.app_sg.id
  cidr_ipv4         = var.admin_cidr
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

# SSH from the app instance to the private instances
locals {
  private_sgs = {
    db        = aws_security_group.db_sg.id
    rabbitmq  = aws_security_group.rabbitmq_sg.id
    memcached = aws_security_group.memcached_sg.id
  }
}

resource "aws_vpc_security_group_ingress_rule" "private_ssh_from_app" {
  for_each                     = local.private_sgs
  description                  = "SSH from app instance to ${each.key}"
  security_group_id            = each.value
  referenced_security_group_id = aws_security_group.app_sg.id
  from_port                    = 22
  ip_protocol                  = "tcp"
  to_port                      = 22
}