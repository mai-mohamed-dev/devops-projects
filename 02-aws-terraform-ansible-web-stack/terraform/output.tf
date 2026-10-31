# VPC
#####################################################
output "vpc_id" {
  description = "ID of the main VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the main VPC"
  value       = aws_vpc.main.cidr_block
}

# Subnets
#####################################################
output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = aws_subnet.private.id
}

# Gateways
#####################################################

output "nat_gateway_public_ip" {
  description = "Elastic IP of the NAT Gateway (outbound IP of private instances)"
  value       = aws_eip.nat.public_ip
}


# Security groups
#####################################################
output "public_sg_id" {
  description = "Security group ID of the public load balancer tier"
  value       = aws_security_group.public_sg.id
}

output "app_sg_id" {
  description = "Security group ID of the application tier"
  value       = aws_security_group.app_sg.id
}

output "db_sg_id" {
  description = "Security group ID of the MariaDB tier"
  value       = aws_security_group.db_sg.id
}

output "rabbitmq_sg_id" {
  description = "Security group ID of the RabbitMQ tier"
  value       = aws_security_group.rabbitmq_sg.id
}

output "memcached_sg_id" {
  description = "Security group ID of the Memcached tier"
  value       = aws_security_group.memcached_sg.id
}

output "alb_dns_name" {
  description = "DNS name users open to reach the application"
  value       = aws_lb.app.dns_name
}