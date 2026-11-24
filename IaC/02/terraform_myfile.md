# AWS Terraform 인프라 구축 요청

## 1. 작업 목표

Terraform을 사용하여 AWS 서울 리전(`ap-northeast-2`)에 네트워크 및 EC2 인프라를 구축하는 프로젝트를 작성해줘.

아래 요구사항을 충족하도록 Terraform 코드를 파일별로 분리하고, 리전과 CIDR 등 주요 설정은 변수로 관리해줘.

## 2. 프로젝트 파일 구조

다음 파일을 생성해줘.

| 파일 | 역할 |
|---|---|
| `provider.tf` | AWS Provider 및 Terraform 설정 |
| `variables.tf` | 리전, CIDR, EC2 사양 등의 변수 정의 |
| `network.tf` | VPC, Subnet, Internet Gateway, Route Table |
| `sg.tf` | Security Group |
| `ec2.tf` | SSH Key Pair 및 EC2 인스턴스 |
| `outputs.tf` | 주요 리소스 정보 출력 |
| `terraform.tfvars.example` | 변수 설정 예시 |
| `.gitignore` | Terraform 상태 파일 및 민감 정보 제외 |

## 3. 구현 요구사항

### 3.1 Provider

- AWS Provider 사용
- 기본 리전: 서울 (`ap-northeast-2`)
- 리전은 변수로 관리
- AWS 인증 정보는 코드에 하드코딩하지 않음
- 필요한 Provider 버전을 명시

### 3.2 VPC

파일: `network.tf`

| 항목 | 값 |
|---|---|
| Name | frodo-vpc |
| Region | ap-northeast-2 |
| CIDR | 172.16.0.0/16 |

- DNS Support 활성화
- DNS Hostnames 활성화

### 3.3 Subnet

파일: `network.tf`

| 구분 | 이름 | Availability Zone | CIDR |
|---|---|---|---|
| Public01 | frodo-public01 | ap-northeast-2a | 172.16.0.0/24 |
| Public02 | frodo-public02 | ap-northeast-2c | 172.16.1.0/24 |
| Private01 | frodo-private01 | ap-northeast-2a | 172.16.10.0/24 |
| Private02 | frodo-private02 | ap-northeast-2c | 172.16.11.0/24 |

구현 조건:

- 모든 Subnet은 `frodo-vpc`에 생성
- Public Subnet은 퍼블릭 IPv4 자동 할당 활성화
- Private Subnet은 퍼블릭 IPv4 자동 할당 비활성화
- AZ와 CIDR은 변수로 관리

### 3.4 Internet Gateway

파일: `network.tf`

- 이름: `frodo-ig`
- `frodo-vpc`에 연결

### 3.5 NAT Gateway

- NAT Gateway는 생성하지 않음

### 3.6 Route Table

파일: `network.tf`

**Public Route Table**

- 이름: `frodo-public-rt`
- 기본 경로: `0.0.0.0/0`
- 대상: `frodo-ig`
- 연결할 Subnet:
  - `frodo-public01`
  - `frodo-public02`

**Private Route Table**

- 이름: `frodo-private-rt`
- 연결할 Subnet:
  - `frodo-private01`
  - `frodo-private02`
- 인터넷 기본 경로를 추가하지 않음
- VPC 내부 통신을 위한 Local Route만 유지

### 3.7 Security Group

파일: `sg.tf`

| 항목 | 값 |
|---|---|
| Name | k3s-sg |
| VPC | frodo-vpc |

**Inbound**

- 프로토콜: TCP
- 포트: 전체 (0~65535)
- Source: `0.0.0.0/0`

**Outbound**

- 프로토콜: 전체
- 포트: 전체
- Destination: `0.0.0.0/0`

요구사항에 따라 모든 TCP 포트를 개방하되, 운영 환경에서는 위험한 설정이라는 주석을 추가해줘.

### 3.8 SSH Key Pair

파일: `ec2.tf`

| 항목 | 값 |
|---|---|
| Key Name | k3s |
| Algorithm | RSA |
| Key Size | 4096bit |
| Private Key | ~/.ssh/k3s.pem |

구현 조건:

- Terraform으로 RSA 키쌍 생성
- 공개키를 AWS EC2 Key Pair에 등록
- 개인키는 Terraform 실행 환경의 `~/.ssh/k3s.pem`에 저장
- 개인키 파일 권한은 `0600`으로 설정
- 개인키가 Terraform State에 포함된다는 보안상 주의사항 명시
- `.ssh` 디렉터리 존재 여부를 고려하여 구현

### 3.9 EC2 Instance

파일: `ec2.tf`

| 항목 | 값 |
|---|---|
| Name | frodo-ec2 |
| AMI | Amazon Linux 2023 |
| Instance Type | t3.medium |
| Architecture | x86_64 |
| Root Storage | 40GiB |
| Storage Type | gp3 |
| SSH Key | k3s |
| Subnet | frodo-public01 |
| Security Group | k3s-sg |
| Public IPv4 | 활성화 |

구현 조건:

- AWS에서 공식 Amazon Linux 2023 AMI 조회
- AMI ID를 하드코딩하지 않음
- 첫 번째 Public Subnet에 배치
- 생성된 SSH Key Pair 사용
- 루트 EBS 볼륨 암호화 활성화

## 4. 변수 관리

`variables.tf`에서 다음 항목을 변수로 관리해줘.

- AWS Region
- VPC CIDR
- 각 Subnet CIDR
- 각 Availability Zone
- EC2 Instance Type
- EC2 Root Volume Size
- SSH Key Pair Name

별도의 사용자 설정 없이도 요구사항에 맞게 생성되도록 기본값을 지정해줘.

## 5. Output 설정

`outputs.tf`에 다음 정보를 출력하도록 구성해줘.

- VPC ID
- Public Subnet IDs
- Private Subnet IDs
- Internet Gateway ID
- EC2 Instance ID
- EC2 Public IP
- EC2 Private IP
- SSH 개인키 저장 경로
- EC2 SSH 접속 명령어

SSH 접속 명령어는 생성된 EC2의 퍼블릭 IP를 동적으로 참조하도록 구현해줘.

## 6. 구현 규칙

1. Terraform HCL 문법과 공식 AWS Provider 리소스를 사용해줘.
2. 리소스 간 참조는 하드코딩하지 말고 Terraform Reference를 활용해줘.
3. 모든 AWS 리소스에 적절한 `Name` 태그를 설정해줘.
4. 불필요한 리소스는 생성하지 마.
5. NAT Gateway, Load Balancer, 추가 EC2는 생성하지 마.
6. 민감 정보가 Git에 포함되지 않도록 `.gitignore`를 작성해줘.
7. 변수 및 리소스 이름은 일관된 규칙으로 작성해줘.
8. 파일별 역할을 명확히 구분해줘.
9. 요구사항에 없는 인프라는 임의로 추가하지 마.

## 7. 검증 요구사항

코드 작성 후 다음 명령어를 기준으로 검증해줘.

- `terraform fmt -check`
- `terraform init`
- `terraform validate`
- `terraform plan`

검증 과정에서 오류가 발생하면 원인을 분석하고 수정해줘.

AWS 인증 정보가 없거나 실제 AWS 접근이 불가능한 경우에는 가능한 로컬 검증까지만 수행하고, 수행하지 못한 검증을 명시해줘.

**실제 AWS 리소스를 생성하거나 삭제하는 `terraform apply`, `terraform destroy`는 실행하지 마.**

## 8. 완료 기준

다음 조건이 충족되면 작업을 완료한 것으로 판단해줘.

- 요구한 Terraform 파일이 모두 생성됨
- VPC와 4개 Subnet이 정의됨
- Internet Gateway 및 Route Table 연결이 구성됨
- NAT Gateway가 생성되지 않음
- Security Group 정책이 요구사항과 일치함
- RSA SSH Key Pair 및 개인키 저장 기능이 구현됨
- EC2가 지정된 사양과 Subnet으로 구성됨
- 주요 설정이 변수로 관리됨
- 출력값이 정의됨
- 가능한 Terraform 검증을 통과함

작업 완료 후 **생성한 파일 목록, 주요 구현 내용, 검증 결과, 실제 배포 전 주의사항**을 간결하게 정리해줘.
