# 남은 문제점 / 한계

*다른 언어: [English](known-limitations.md), [日本語](known-limitations.ja.md)*

이 설계를 실무에 가깝게 가져갈 때 남는 갭입니다. 이 레포에서는 **의도적으로 문서만** 남기고 구현하지 않았습니다.

## 1. Workload Identity Federation (WIF)

**문제:** GitHub → 클라우드 인증은 WIF(키리스)가 바람직하지만, 이 스택은 **Cloud Build 중심**이라 GitHub Actions 러너에서처럼 WIF를 자연스럽게 쓰기 어렵습니다.

**대응 방향:** WIF를 제대로 쓰려면 Cloud Build에 억지로 맞추기보다 **GitHub Actions로의 마이그레이션(또는 병행)** 이 필요합니다.

**이 레포 상태:** 미구현. 키리스 인증을 강화할 때의 필수 방향으로만 기록.

## 2. 빌드 / executor SA 최소 권한

**문제:** 데모 IAM은 파이프라인을 쉽게 올리기 위해 권한이 거칠습니다(예: 워크로드 프로젝트에 Terraform SA `roles/editor`).

**대응 방향:** 실제 운용에서는 빌드(executor) SA와 terraform SA를 **환경·리소스 유형별로 최소 권한으로 세부 조정**해야 합니다(state 버킷만, 필요한 API만, blanket editor 금지). 모듈/서비스가 늘어날 때마다 권한 표를 재검토합니다.

**이 레포 상태:** 데모용 넓은 역할. 실무에서는 IAM 매트릭스 세분화가 필요.

## 3. Plan artifact 승계

**문제:** Apply 빌드에서 `terraform plan`을 다시 만든 뒤 apply합니다. PR에서 리뷰한 plan 바이너리와 apply가 고정되어 있지 않습니다.

**대응 방향:** 리뷰된 `tfplan`(Terraform 버전·lock 메타데이터 포함)을 GCS/artifacts에 저장하고, 태그 + 승인 후 **그 artifact만** apply.

**이 레포 상태:** 미구현.

## 4. Policy-as-code / 머지 게이트

**문제:** 품질 게이트가 fmt / validate / TFLint / Trivy까지입니다. OPA/Conftest 등 policy-as-code나 CODEOWNERS·필수 리뷰는 이 Terraform 밖입니다.

**대응 방향:** 변경 통제를 강화하려면 policy-as-code와 브랜치 보호를 운영 모델에 포함.

**이 레포 상태:** 미구현.

## 5. Drift 상시 통제

**문제:** Apply YAML에 apply 직후 drift 체크는 있지만, 스케줄 drift 잡·알림은 없습니다.

**대응 방향:** 주기적 `terraform plan -detailed-exitcode`(또는 동등 수단) + 예상치 못한 drift 알림.

**이 레포 상태:** apply 파이프라인 일회성 체크만.

## 요약

| 항목 | 데모 | 실무 방향 |
|---|---|---|
| CI → GCP 인증 | Cloud Build + SA impersonation | **WIF는 GitHub Actions 마이그레이션이 필요** |
| SA 권한 | 넓음 (예: editor) | **최소 권한으로 세부 조정** |
| Plan → apply | apply 시 재 plan | **리뷰된 plan artifact 승계** |
| Policy / 리뷰 | lint + scan | Policy-as-code + 필수 리뷰 |
| Drift | apply 직후만 | 스케줄 drift + 알림 |
