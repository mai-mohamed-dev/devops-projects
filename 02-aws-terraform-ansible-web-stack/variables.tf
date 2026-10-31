variable "vpc_cidr"{
    default = "10.0.0.0/16"
    type = string
    description = "(VPC) with CIDR block 10.0.0.0/16"
}
variable "av_zone"{
    default = "eu-north-1a" 
    type = string
    description = "subnet availability zone"
}
variable "av_zone_2"{
    default = "eu-north-1b" 
    type = string
    description = "subnet availability zone"
}
variable "public_cidr"{
    default = "10.0.1.0/24"
    type = string
    description = "public subnet with CIDR block 10.0.1.0/24"
}
variable "public_cidr_2" {
  description = "CIDR block of the second public subnet"
  type        = string
  default     = "10.0.3.0/24"
}
variable "private_cidr"{
    default = "10.0.2.0/24"
    type = string
    description = "private subnet with CIDR block 10.0.2.0/24"
}
variable "key_name" {
    description = "Name of an EXISTING EC2 key pair (for SSH and Ansible)"
    type        = string
}

variable "app_port" {
    description = "Port the app instance answers on (Nginx = 80)"
    type        = number
    default     = 80
}

variable "admin_cidr" {
    description = "Your public IP in CIDR form, e.g. 203.0.113.10/32"
    type        = string
}