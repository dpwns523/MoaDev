# 플랫폼 토폴로지

이 문서는 현재 저장소의 플랫폼 구성을 가장 빠르게 이해하기 위한 입구 문서입니다.

영문판: [platform-topology.md](platform-topology.md)

이 문서는 `ops/env`, `ansible/group_vars`, `infra/terraform/envs/*` 아래에 체크인된 샘플 설정 파일을 기준으로 작성되었습니다. 현재 샘플은 AWS에 control plane을 두고, AWS와 OCI에 worker pool을 나누어 둔 하나의 논리적 멀티클라우드 Kubernetes 클러스터를 설명합니다.

![MoaDev 플랫폼 토폴로지](assets/diagrams/platform-topology.svg)

## 1분 요약

- 현재 샘플 토폴로지는 AWS 클러스터와 OCI 클러스터를 분리한 모델이 아니라 `multicloud` 모델입니다.
- AWS가 control plane provider 이며, AWS 안에도 worker pool 이 있습니다.
- OCI는 같은 클러스터에 추가 worker pool 을 제공합니다.
- 공통 토폴로지 값은 shared config block 에 둡니다.
- compute, subnet, storage 같은 클라우드별 세부값은 provider 전용 block 에 둡니다.

## 쉬운 설명

플랫폼을 네 층으로 나누어 보면 이해가 쉽습니다.

1. 공통 의도: 클러스터 이름, Kubernetes 버전, Pod CIDR, Service CIDR 같은 값은 하나의 논리적 클러스터 기준으로 공유합니다.
2. AWS control plane: control plane 은 AWS 쪽 인프라 primitive 를 기준으로 운영하는 방향입니다.
3. 양쪽 클라우드의 worker capacity: `aws_workers` 와 `oci_workers` 가 같은 클러스터의 worker node group 으로 붙습니다.
4. 배포와 운영: Helm 이 패키징을 담당하고 Argo CD 가 승격을 담당하며, ingress 와 관측성 연동은 현재 샘플상 AWS 중심 기본값을 가집니다.

현재 샘플 값은 이 구조를 그대로 보여줍니다.

- `platform_topology = multicloud`
- `control_plane_provider = aws`
- `aws_control_plane.desired_count = 1`
- `aws_workers.desired_count = 3`
- `oci_workers.desired_count = 3`
- `load_balancer_provider = aws`
- `default_node_group = aws_workers`

## environment 와 provider 의 차이

이 둘은 같은 의미가 아니며, 섞어 쓰면 안 됩니다.

| 용어 | 의미 | 예시 값 | 주로 나타나는 곳 |
|------|------|---------|-------------------|
| `environment` | 어떤 배포 단계인지 | `dev`, `prod` | 파일 경로, 릴리스 흐름, 환경별 샘플 값 |
| `provider` | 특정 인프라 primitive 를 어느 클라우드가 소유하는지 | `aws`, `oci` | `control_plane_provider`, node group provider, cloud override block |
| `platform_topology` | 전체 배포 형태가 단일 클라우드인지 멀티클라우드인지 | `single-provider`, `multicloud` | 공통 토폴로지 계약 |

실무 규칙은 간단합니다.

- `environment` 는 어떤 값 묶음을 적용할지 고릅니다.
- `provider` 는 어떤 클라우드 block 에서 compute, network, storage 세부값을 가져올지 고릅니다.
- `platform_topology` 는 런타임 모양 자체를 설명합니다.

## 도구 경계

| 도구 | 책임 | 책임 아님 |
|------|------|-----------|
| Terraform | cloud primitive, VPC/VCN, subnet, instance, storage class, 향후 provider plumbing | 앱 릴리스 타이밍, Kubernetes 패키지 템플릿 |
| Ansible | 호스트 준비와 mutable operator input 적용 | 클라우드 리소스 lifecycle |
| Kubespray | 클러스터 bootstrap 과 node join | 앱 패키징, GitOps 승격 |
| Helm | workload 패키징과 Kubernetes manifest | 인스턴스 생성, 호스트 bootstrap |
| Argo CD | 환경 승격과 sync orchestration | 저수준 클러스터 bring-up |

짧게 말하면:

- Terraform 이 클러스터가 올라갈 자리를 만듭니다.
- Ansible 과 Kubespray 가 그 자리를 실제 클러스터로 바꿉니다.
- Helm 이 무엇을 배포할지 정의합니다.
- Argo CD 가 어느 환경에 언제 반영할지 결정합니다.

## 설정 handoff

같은 논리 모델이 현재 세 가지 샘플 표면으로 투영됩니다.

| 샘플 표면 | 목적 | 현재 장점 |
|-----------|------|-----------|
| `ops/env/*.env.example` | 운영자와 스크립트를 위한 평면형 환경 변수 뷰 | 빠르게 훑기 쉽고 shell 친화적 |
| `ansible/group_vars/*.yml.example` | bootstrap 과 config management 용 계층형 값 | Ansible/Kubespray 관점에서 읽기 쉬움 |
| `infra/terraform/envs/*/terraform.tfvars.example` | Terraform 입력 모델 | 공통 토폴로지와 provider override 를 명시적으로 분리 |

공통으로 유지해야 하는 그룹:

- `cluster_topology`
- `domains`
- `images`
- `namespaces`
- `ingress`
- `scheduling`
- `cicd`
- `monitoring`
- `storage`
- `cost_automation`

provider 별로 유지해야 하는 그룹:

- `aws_cluster`
- `oci_cluster`

## 현재 비목표

- 이 문서는 live Terraform module 이 이미 전체 토폴로지를 구현했다고 주장하지 않습니다.
- 이 문서는 AWS worker 와 OCI worker 사이의 최종 workload placement policy 를 고정하지 않습니다.
- 이 문서는 저장소의 현재 방향을 다시 AWS/OCI 분리 클러스터 모델로 되돌리지 않습니다.

## 출처 메모

다이어그램은 공식 AWS Architecture Icons 패키지와 공식 Oracle OCI 아이콘 툴킷에서 가져온 벤더 자산을 저장소 안에 vendoring 해서 사용합니다.
