output "cluster_name" {
  description = "EKS 클러스터 이름"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS 클러스터 API 서버 엔드포인트"
  value       = module.eks.cluster_endpoint
}

output "oidc_provider_arn" {
  description = "EKS OIDC Provider ARN (IRSA 설정에 사용)"
  value       = module.eks.oidc_provider_arn
}

output "nodegroup_role_arn" {
  description = "EKS 관리형 노드 그룹 IAM Role ARN"
  value       = module.eks.eks_managed_node_groups["default"].iam_role_arn
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private 서브넷 ID 목록 (워커 노드 배치 위치)"
  value       = module.vpc.private_subnets
}

# ============================================================
# 적용 후 검증 체크리스트
# ============================================================
# 1. 노드 상태 확인
#    kubectl get nodes
#
# 2. 전체 파드 상태 확인
#    kubectl get pods -A
#
# 3. EBS CSI 드라이버 애드온 상태 확인
#    kubectl get pods -n kube-system -l app=ebs-csi-controller
#    aws eks describe-addon --cluster-name <cluster_name> --addon-name aws-ebs-csi-driver
#
# 4. AWS Load Balancer Controller 상태 확인
#    kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
#    kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
