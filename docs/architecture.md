# Architecture

## Goals

실무에서 Terraform을 안전하게 운용하기 위한 CI/CD를 구성합니다.

1. **변경된 프로젝트만 plan** — 불필요한 전체 plan 방지
2. **Apply는 태그 + 수동 승인** — 실수로 바로 apply되지 않도록 차단
3. **권한 분리** — executor SA가 빌드를 돌리고, terraform SA만 인프라 변경
4. **점진 롤아웃** — `enabled_envs` 로 환경별 활성화

## Plan (PR)

각 워크로드 경로마다 트리거가 있고, `included_files` 로 범위를 좁힙니다.

```hcl
included_files = ["envs/${each.value}/**"]
```

예시:

- PR에서 `envs/dev/demo-app-dev/**` 만 수정 → `dev/demo-app-dev` plan만 실행
- `envs/prd/demo-app-prd/**` 는 변경 없음 → prd plan은 실행되지 않음

## Apply (tag + approval)

1. 태그 푸시: `<project>_.*` (예: `demo-app-dev_v1.0.0`)
2. Cloud Build apply 트리거가 감지
3. **`approval_required = true`** → 콘솔에서 **Approve** 해야 apply step이 진행

prd뿐만 아니라 apply 트리거 전체에 승인을 요구합니다.

## Components

### Control project (`demo-cicd-control`)

- GitHub App connection / linked repository
- Path-filtered plan triggers + tag apply triggers (approval)
- Per-env executor SA / terraform SA
- Secret Manager (`GITHUB_TOKEN` for tfcmt)

### Workload projects (`demo-app-dev`, `demo-app-prd`)

- Sample Terraform under `envs/<env>/<project>/`
- Triggers do not live here

## Trust boundary

```text
Cloud Build service agent
  └─ ActAs → executor SA
       └─ TokenCreator → terraform SA
            └─ roles/editor (or tighter) on target workload project
```

Build steps set:

```text
GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=${_TF_SA}
```

## Progressive enablement

```hcl
enabled_envs = ["dev"]          # start here
# enabled_envs = ["dev", "prd"] # expand later
```

Only listed envs create SAs, IAM bindings, and triggers.

## Known limitations

See [known-limitations.md](known-limitations.md) for remaining production gaps (WIF / GitHub Actions migration, SA least privilege tuning, plan artifact promotion, etc.).
