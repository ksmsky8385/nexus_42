variable "cluster_name" {
  description = "EKS 클러스터 이름 (VPC 이름 등 연관 리소스에도 반영됩니다)"
  type        = string
  default     = "frodo"
}

variable "region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "cluster_version" {
  description = "EKS 클러스터 Kubernetes 버전"
  type        = string
  default     = "1.35"
}

variable "node_desired_size" {
  description = "워커 노드 기본(desired) 수"
  type        = number
  default     = 3
}

variable "node_min_size" {
  description = "워커 노드 최소 수"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "워커 노드 최대 수"
  type        = number
  default     = 5
}

variable "node_instance_types" {
  description = "워커 노드 EC2 인스턴스 타입 목록"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_disk_size" {
  description = "워커 노드 루트 볼륨 크기 (GiB)"
  type        = number
  default     = 20
}

variable "node_capacity_type" {
  description = "워커 노드 용량 타입 (ON_DEMAND: 안정적, SPOT: 비용 절감)"
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.node_capacity_type)
    error_message = "node_capacity_type은 ON_DEMAND 또는 SPOT 이어야 합니다."
  }
}

variable "ebs_csi_addon_version" {
  description = "EBS CSI 드라이버 애드온 버전 (EKS 클러스터 버전에 맞는 버전 확인 필요)"
  type        = string
  default     = "v1.56.0-eksbuild.1"
}
