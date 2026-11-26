# EKS ALB 컨트롤러 IAM 정책 이름 충돌

- 발생일: 2026-11-26
- 대상: `ap-northeast-2`의 `frodo` EKS 클러스터
- Terraform 작업 경로: `nexus_42/eks/code`
- 워크스페이스: `default`

## 증상

`terraform apply`에서 리소스 3개를 추가할 예정이었으나, `aws_iam_policy.alb_controller`를 생성하는 단계에서 다음 오류로 중단됐다.

```text
EntityAlreadyExists: A policy called frodo-alb-controller-policy already exists.
Duplicate names are not allowed. (HTTP 409)
```

## 원인과 확인 결과

`addons.tf`는 정책 이름을 `${var.cluster_name}-alb-controller-policy`로 지정한다. 클러스터 이름이 `frodo`여서 AWS에 이미 존재하던 `frodo-alb-controller-policy`와 이름이 겹쳤다. 현재 Terraform state에는 해당 정책 주소가 없어서 Terraform이 신규 생성을 시도했다.

AWS CLI로 조회한 결과 기존 정책에 연결된 역할·사용자·그룹은 없었다. `frodo-alb-controller-role`은 AWS와 Terraform state에 모두 있었고, 연결된 관리형 정책은 없었다. EKS 클러스터는 `ACTIVE`였으며, `kube-system`에는 컨트롤러 Deployment가 없었다. 정책 생성이 실패하면서 그에 의존하는 IAM 정책 연결과 Helm 배포도 진행되지 않았다.

## 해결 절차

기존 정책을 재사용했다. IAM에서 조회한 실제 정책 ARN을 사용해 현재 Terraform state의 `aws_iam_policy.alb_controller` 주소로 가져왔다.

```bash
terraform import aws_iam_policy.alb_controller '<기존 IAM 정책 ARN>'
terraform plan -out=alb-controller.tfplan
```

계획에 아래 두 리소스 추가만 있고 변경과 삭제가 각각 0건임을 확인한 뒤, 저장한 계획을 적용했다.

- `aws_iam_role_policy_attachment.alb_controller` — 기존 정책을 `frodo-alb-controller-role`에 연결
- `helm_release.alb_controller` — `kube-system`에 AWS Load Balancer Controller 배포

```bash
terraform apply alb-controller.tfplan
```

같은 오류를 복구할 때는 import 전에 해당 정책이 다른 Terraform state에서 관리되는지 확인한다. 이번 진단에서는 다른 state의 관리 여부까지 확인하지 못했다.

## 검증 결과

- `terraform apply` 성공. 2개 추가, 0개 변경, 0개 삭제.
- `kube-system/aws-load-balancer-controller` Deployment는 `2/2 Ready`였고, Pod 2개는 모두 `Running`이었다.
- 후속 `terraform plan`은 `No changes`를 반환했다.
- 실제 Ingress를 통한 AWS 로드 밸런서 생성은 검증 범위에 포함하지 않았다.
