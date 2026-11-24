# Terraform AWS 인프라 구축 계획서 (`PLAN.md`)

본 문서는 요청된 조건에 맞춰 AWS 클라우드 인프라를 Terraform으로 구축하기 위한 설계 및 구현 계획서입니다. 실제 테라폼 코드 작성 전 파일 구조, 변수 설계, 리소스 명세 및 주의사항을 정의합니다.

---

## 1. 디렉토리 및 파일 구조

코드의 가독성과 유지보수성을 위해 기능별로 파일을 분리하여 구성합니다.

```text
terraform-frodo-infra/
├── PLAN.md          # 인프라 구축 계획서 (현재 문서)
├── provider.tf      # Terraform 및 AWS, TLS, Local Provider 설정
├── variables.tf     # 리전, CIDR, 인스턴스 스펙 등 변수 선언 및 기본값 설정
├── network.tf       # VPC, Subnet, Internet Gateway, Routing Table 구성
├── sg.tf            # Security Group (k3s-sg) 및 인/아웃바운드 규칙 구성
└── ec2.tf           # SSH Key Pair 생성/저장, Amazon Linux 2023 AMI 조회 및 EC2 생성
```

---

## 2. 변수 설계 (`variables.tf`)

유연한 환경 구성을 위해 주요 설정값은 변수로 처리하며, `default` 값을 통해 요청된 기본 설정을 반영합니다.

* **`aws_region`**: 기본값 `"ap-northeast-2"` (서울 리전)
* **`vpc_cidr`**: 기본값 `"172.16.0.0/16"`
* **`public_subnet_cidrs`**: 기본값 `["172.16.0.0/24", "172.16.1.0/24"]`
* **`private_subnet_cidrs`**: 기본값 `["172.16.10.0/24", "172.16.11.0/24"]`
* **`availability_zones`**: 기본값 `["ap-northeast-2a", "ap-northeast-2c"]`
* **`instance_type`**: 기본값 `"t3.medium"`
* **`root_volume_size`**: 기본값 `40` (GB)

---

## 3. 상세 리소스 구현 계획

### 3.1. Provider 설정 (`provider.tf`)
* **`aws`**: 리전 변수(`var.aws_region`)를 참조하여 AWS 리소스 제어.
* **`tls`**: 로컬 환경에서 RSA 방식의 SSH 개인키/공개키 쌍을 동적으로 생성하기 위해 사용 (`tls_private_key`).
* **`local`**: 생성된 SSH 개인키를 로컬 파일 시스템(`~/.ssh/k3s.pem`)에 저장하고 권한(`0400`)을 설정하기 위해 사용 (`local_file`).

### 3.2. 네트워크 구성 (`network.tf`)
1. **VPC (`aws_vpc`)**
   * **Name 태그**: `frodo-vpc`
   * **CIDR**: `172.16.0.0/16`
   * DNS 호스트네임 및 DNS 지원 활성화 설정 (`enable_dns_hostnames = true`, `enable_dns_support = true`).
2. **Subnets (`aws_subnet`)**
   * **Public Subnets** (퍼블릭 IP 자동 할당 옵션 `map_public_ip_on_launch = true` 적용 권장)
     * `frodo-public01`: `ap-northeast-2a` / `172.16.0.0/24`
     * `frodo-public02`: `ap-northeast-2c` / `172.16.1.0/24`
   * **Private Subnets**
     * `frodo-private01`: `ap-northeast-2a` / `172.16.10.0/24`
     * `frodo-private02`: `ap-northeast-2c` / `172.16.11.0/24`
3. **Internet Gateway (`aws_internet_gateway`)**
   * **Name 태그**: `frodo-ig`
   * `frodo-vpc`에 연결.
4. **NAT Gateway**: 생성하지 않음 (요구사항 반영).
5. **Routing Tables (`aws_route_table` & `aws_route_table_association`)**
   * **`frodo-public-rt`**:
     * 기본 경로(`0.0.0.0/0`)를 `frodo-ig`로 라우팅.
     * `frodo-public01`, `frodo-public02` 서브넷과 명시적 연결.
   * **`frodo-private-rt`**:
     * 별도의 외부 라우팅(NAT 등) 없이 로컬 VPC 통신만 허용.
     * `frodo-private01`, `frodo-private02` 서브넷과 명시적 연결.

### 3.3. 보안 그룹 (`sg.tf`)
* **Security Group (`aws_security_group`)**
  * **이름 / Name 태그**: `k3s-sg`
  * **소속 VPC**: `frodo-vpc`
  * **인바운드 정책 (Ingress)**:
    * 프로토콜: `TCP` (포트 범위: `0` ~ `65535`)
    * 소스: `0.0.0.0/0` (Any)
  * **아웃바운드 정책 (Egress)**:
    * 프로토콜: `All` (`-1`, 모든 포트/프로토콜)
    * 대상: `0.0.0.0/0` (Any)

### 3.4. SSH 키쌍 및 EC2 인스턴스 (`ec2.tf`)
1. **SSH Key Pair**
   * `tls_private_key` 리소스를 통해 `RSA` 알고리즘(4096비트 권장)으로 키 생성.
   * `aws_key_pair` 리소스로 생성된 공개키를 AWS에 등록 (키 이름: `k3s`).
   * `local_file` 리소스를 사용하여 개인키(PEM 형식)를 실행 사용자의 홈 디렉토리 하위 `~/.ssh/k3s.pem` 경로에 저장 (`pathexpand("~/.ssh/k3s.pem")` 활용) 및 파일 권한 `0400` 지정.
2. **AMI 데이터 소스 (`aws_ami`)**
   * 최신 **Amazon Linux 2023** (`al2023-ami-2023.*-x86_64`) 공식 이미지를 동적으로 조회하여 사용.
3. **EC2 인스턴스 (`aws_instance`)**
   * **AMI**: 조회된 Amazon Linux 2023 ID
   * **인스턴스 타입**: `t3.medium`
   * **루트 볼륨 (`root_block_device`)**: `40GB` (`gp3` 타입 권장)
   * **키 페어**: `k3s`
   * **서브넷**: `frodo-public01` (첫 번째 퍼블릭 서브넷)
   * **보안 그룹**: `k3s-sg`
   * **퍼블릭 IP**: 외부 SSH 접속을 위해 퍼블릭 IP 할당 활성화 (`associate_public_ip_address = true`).

---

## 4. 실행 및 검증 계획 (Workflow)

코드 작성 완료 후 아래 단계에 따라 인프라를 배포하고 검증할 예정입니다.

1. **`terraform init`**: AWS, TLS, Local 프로바이더 플러그인 초기화.
2. **`terraform plan`**: 리소스 생성 계획 및 변수 매핑 상태 사전 검토.
3. **`terraform apply`**: 실제 AWS 인프라 배포 및 로컬 `~/.ssh/k3s.pem` 파일 생성 확인.
4. **접속 테스트**: 생성된 EC2의 퍼블릭 IP와 `~/.ssh/k3s.pem` 키를 이용해 SSH 접속 확인 (`ssh -i ~/.ssh/k3s.pem ec2-user@<EC2_PUBLIC_IP>`).