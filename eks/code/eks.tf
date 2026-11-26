# 노드 간 All Traffic 허용 보안 그룹 (Self-referencing Ingress Rule)
resource "aws_security_group" "node_sg" {
  name        = "${var.cluster_name}-node-sg"
  description = "Allow all traffic between nodes belonging to this security group"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow all traffic from nodes in the same SG"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.cluster_name}-node-sg"
    Cluster = var.cluster_name
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.8"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_encryption_config = {}
  create_kms_key            = false

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    default = {
      desired_size = var.node_desired_size
      min_size     = var.node_min_size
      max_size     = var.node_max_size

      instance_types = var.node_instance_types
      capacity_type  = var.node_capacity_type

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = var.node_disk_size
            volume_type           = "gp3"
            delete_on_termination = true
          }
        }
      }

      subnet_ids             = module.vpc.private_subnets
      vpc_security_group_ids = [aws_security_group.node_sg.id]
    }
  }

  tags = {
    Terraform = "true"
    Cluster   = var.cluster_name
  }
}

# 전제조건: aws CLI가 설치되어 있고, 유효한 AWS 인증 프로필이 로컬에 설정되어 있어야 합니다.
# cluster_name, region, cluster_version 변경 시 자동으로 재실행됩니다.
resource "null_resource" "update_kubeconfig" {
  triggers = {
    cluster_name    = var.cluster_name
    region          = var.region
    cluster_version = var.cluster_version
  }

  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --name ${var.cluster_name} --region ${var.region}"
  }

  depends_on = [module.eks]
}
