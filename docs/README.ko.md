# gcp-cloudbuild-advanced

*다른 언어: [English](../README.md), [日本語](README.ja.md)*

실무에 가까운 Terraform 운용을 위한 GCP Cloud Build CI/CD입니다.

경로 필터 plan, 태그 기반 apply + 수동 승인, 중앙 집중 트리거, least-privilege SA impersonation으로 Terraform을 안전하게 운용하는 구성을 정리했습니다.

## 동작 방식

| 단계 | 트리거 | 동작 |
|---|---|---|
| **Plan** | Pull Request | `envs/<env>/<project>/**` 에 **변경이 있는 프로젝트만** plan 실행 |
| **Apply** | Tag push (`<project>_.*`) | **Cloud Build 승인(Approve)** 후에만 apply 진행 |

- Plan은 경로별 `included_files`로 필터링되어, 변경 없는 프로젝트는 실행되지 않습니다.
- Apply는 태그 푸시 후 Cloud Build 콘솔의 승인 버튼을 눌러야 진행됩니다.

## 기능과 목적

| 기능 | 목적 |
|---|---|
| **경로 필터 PR plan** | 전체 레포 plan을 피하고, 변경된 워크로드만 `terraform plan`을 돌려 리뷰 시간과 노이즈를 줄입니다. |
| **태그 기반 apply** | 리뷰(PR/plan)와 배포(tag)를 분리합니다. apply는 merge의 부수효과가 아니라 의도된 릴리스 행위입니다. |
| **Apply 수동 승인** | 인프라 변경 전 사람 확인 단계를 둡니다. 태그 푸시만으로 바로 apply되지 않게 합니다. |
| **트리거 중앙 집약 (제어 프로젝트)** | 워크로드 프로젝트마다 트리거를 흩뿌리지 않고 한곳에서 CI/CD를 관리해 감사·소유권을 명확히 합니다. |
| **Executor SA → Terraform SA impersonation** | 빌드 실행 주체와 인프라 변경 주체를 분리합니다. 빌드 침해 시 영향 범위를 줄입니다. |
| **`enabled_envs` 점진 롤아웃** | `dev`부터 켠 뒤 `prd`를 추가하는 식으로, 전 환경을 한 번에 연결하지 않고 안전하게 확대합니다. |
| **PR tfcmt 코멘트** | plan 결과를 PR 코멘트로 남겨, Cloud Build 로그를 뒤지지 않고도 인프라 변경을 리뷰할 수 있게 합니다. |
| **품질 게이트 (fmt / validate / TFLint / Trivy)** | apply 전에 포맷·문법·흔한 Terraform 실수·높은 위험도 IaC 이슈를 걸러냅니다. |
| **GitHub App 연동** | 개인 PAT에 의존하지 않고 Cloud Build 공식 GitHub 연동으로 저장소에 접근합니다. |

## 아키텍처

```text
GitHub PR  (변경된 envs/<project>만)
        │
        ▼
 Cloud Build plan  ──▶  tfcmt (PR comment)

GitHub tag  (<project>_*)
        │
        ▼
 Cloud Build apply  ──▶  [Approval required]  ──▶  terraform apply
```

상세: [architecture.md](architecture.md)

## 디렉터리 구성

```text
.
├── cloudbuild/           # Cloud Build 파이프라인 YAML
│   ├── plan.yaml
│   └── apply.yaml
├── platform/             # CI/CD 제어면 (Terraform)
│   ├── connection.tf     # GitHub App connection / repository
│   ├── iam.tf            # executor / terraform SA + impersonation
│   ├── triggers.tf       # 경로 필터 plan / 태그 apply (+ 승인)
│   ├── project-list.tf   # 워크로드 프로젝트 목록 (데모 ID OK)
│   └── locals.tf         # enabled_envs 기반 파생 locals
├── envs/                 # 샘플 워크로드
│   ├── dev/
│   └── prd/
└── docs/
```

## 빠른 시작

1. GCP에 control / workload 프로젝트를 준비합니다.
2. GitHub App을 설치하고 OAuth 토큰을 Secret Manager에 저장합니다.
3. `platform/terraform.tfvars.example` → `terraform.tfvars` 로 복사합니다.
4. `enabled_envs = ["dev"]` 로 platform을 적용합니다.
5. `envs/...` 한 경로만 바꾼 PR을 올리면 해당 프로젝트 plan만 실행됩니다.
6. `demo-app-dev_v1.0.0` 같은 태그를 푸시한 뒤 Cloud Build에서 **Approve** 하면 apply가 실행됩니다.

```bash
cd platform
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars
terraform init
terraform plan
```

## 남은 문제점

WIF는 Cloud Build 환경에서 쓰기 어렵고 GitHub Actions 마이그레이션이 필요하다는 점, 실무에서 빌드 SA 최소 권한 세부 조정, plan artifact 승계 등은 [known-limitations.ko.md](known-limitations.ko.md) 에 모아 두었습니다.

## Topics

`gcp` · `terraform` · `cloud-build` · `github-app` · `cicd` · `iam` · `impersonation`
