variable "aws_region" {
  description = "AWS region where the VPC will be created."
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "Prefix used for resource names and tags."
  type        = string
  default     = "frodo"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "172.17.0.0/16"
}

variable "public_subnets" {
  description = "Public subnet definitions keyed by logical subnet name."
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))
  default = {
    public01 = {
      cidr_block        = "172.17.0.0/24"
      availability_zone = "ap-northeast-2a"
    }
    public02 = {
      cidr_block        = "172.17.10.0/24"
      availability_zone = "ap-northeast-2c"
    }
  }
}

variable "private_subnets" {
  description = "Private subnet definitions keyed by logical subnet name."
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))
  default = {
    private01 = {
      cidr_block        = "172.17.100.0/24"
      availability_zone = "ap-northeast-2a"
    }
    private02 = {
      cidr_block        = "172.17.110.0/24"
      availability_zone = "ap-northeast-2c"
    }
  }
}
