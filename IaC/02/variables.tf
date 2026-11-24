variable "aws_region" {
  description = "AWS region where resources will be created."
  type        = string
  default     = "ap-northeast-2"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "172.16.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones used by the subnets."
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2c"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets."
  type        = list(string)
  default     = ["172.16.0.0/24", "172.16.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets."
  type        = list(string)
  default     = ["172.16.10.0/24", "172.16.11.0/24"]
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.medium"
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB."
  type        = number
  default     = 40
}

variable "ssh_key_name" {
  description = "Name of the EC2 key pair."
  type        = string
  default     = "k3s"
}

variable "ssh_private_key_path" {
  description = "Path where the generated private key will be saved."
  type        = string
  default     = "~/.ssh/k3s.pem"
}
