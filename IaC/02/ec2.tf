locals {
  ssh_private_key_path_expanded = pathexpand(var.ssh_private_key_path)
  ssh_private_key_dir           = dirname(local.ssh_private_key_path_expanded)
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "tls_private_key" "k3s" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "k3s" {
  key_name   = var.ssh_key_name
  public_key = tls_private_key.k3s.public_key_openssh

  tags = merge(local.common_tags, {
    Name = var.ssh_key_name
  })
}

resource "terraform_data" "ssh_directory" {
  provisioner "local-exec" {
    command = "mkdir -p '${local.ssh_private_key_dir}'"
  }
}

# Security note: Terraform-generated private keys are stored in state.
# Protect local and remote state files, or import an externally managed key instead.
resource "local_sensitive_file" "k3s_private_key" {
  content              = tls_private_key.k3s.private_key_pem
  filename             = local.ssh_private_key_path_expanded
  file_permission      = "0600"
  directory_permission = "0700"

  depends_on = [terraform_data.ssh_directory]
}

resource "aws_instance" "frodo" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public["public01"].id
  vpc_security_group_ids      = [aws_security_group.k3s.id]
  key_name                    = aws_key_pair.k3s.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  tags = merge(local.common_tags, {
    Name = "frodo-ec2"
  })
}
