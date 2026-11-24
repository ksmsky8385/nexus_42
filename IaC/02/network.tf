locals {
  common_tags = {
    Project   = "frodo"
    ManagedBy = "terraform"
  }

  public_subnets = {
    public01 = {
      name              = "frodo-public01"
      cidr_block        = var.public_subnet_cidrs[0]
      availability_zone = var.availability_zones[0]
    }
    public02 = {
      name              = "frodo-public02"
      cidr_block        = var.public_subnet_cidrs[1]
      availability_zone = var.availability_zones[1]
    }
  }

  private_subnets = {
    private01 = {
      name              = "frodo-private01"
      cidr_block        = var.private_subnet_cidrs[0]
      availability_zone = var.availability_zones[0]
    }
    private02 = {
      name              = "frodo-private02"
      cidr_block        = var.private_subnet_cidrs[1]
      availability_zone = var.availability_zones[1]
    }
  }
}

resource "aws_vpc" "frodo" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.common_tags, {
    Name = "frodo-vpc"
  })
}

resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id                  = aws_vpc.frodo.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = each.value.name
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  for_each = local.private_subnets

  vpc_id                  = aws_vpc.frodo.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = false

  tags = merge(local.common_tags, {
    Name = each.value.name
    Tier = "private"
  })
}

resource "aws_internet_gateway" "frodo" {
  vpc_id = aws_vpc.frodo.id

  tags = merge(local.common_tags, {
    Name = "frodo-ig"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.frodo.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.frodo.id
  }

  tags = merge(local.common_tags, {
    Name = "frodo-public-rt"
    Tier = "public"
  })
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.frodo.id

  tags = merge(local.common_tags, {
    Name = "frodo-private-rt"
    Tier = "private"
  })
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}
