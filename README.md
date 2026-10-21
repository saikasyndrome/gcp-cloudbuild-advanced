# gcp-cloudbuild-advanced

*Read this in other languages: [한국어](docs/README.ko.md), [日本語](docs/README.ja.md)*

Production-minded Terraform CI/CD on GCP Cloud Build.

This repository shows how to operate Terraform closer to real-world practice: path-filtered plans, tag-based apply with manual approval, centralized triggers, and least-privilege SA impersonation.

## How it works

| Stage | Trigger | Behavior |
|---|---|---|
| **Plan** | Pull Request | Runs plan **only for projects with changes** under `envs/<env>/<project>/**` |
| **Apply** | Tag push (`<project>_.*`) | Starts apply only after **Cloud Build Approve** |

- Plan uses per-path `included_files`, so unchanged projects are skipped.
- Apply waits for a manual approval button in the Cloud Build console after the tag is pushed.

## Features and purpose

| Feature | Purpose |
|---|---|
| **Path-filtered PR plan** | Avoid full-repo plans. Only the changed workload runs `terraform plan`, which saves time and reduces noise in reviews. |
| **Tag-based apply** | Separate review (PR/plan) from deployment (tag). Apply is an intentional release action, not a merge side effect. |
| **Manual approval on apply** | Add a human gate before infrastructure changes. Prevents accidental apply even after a tag push. |
| **Centralized triggers (control project)** | Manage CI/CD in one place instead of scattering triggers across every workload project. Easier audit and ownership. |
| **Executor SA → Terraform SA impersonation** | Split duties: the build runner and the identity that mutates infra are different. Limits blast radius if a build is compromised. |
| **`enabled_envs` progressive rollout** | Enable `dev` first, then `prd`. Roll out CI/CD safely without wiring every environment at once. |
| **tfcmt on PR** | Post plan results as PR comments so reviewers can discuss infra changes without digging through Cloud Build logs. |
| **Quality gates (fmt / validate / TFLint / Trivy)** | Catch formatting issues, invalid config, common Terraform mistakes, and high/critical IaC findings before apply. |
| **GitHub App connection** | Use Cloud Build’s first-party GitHub integration instead of brittle personal tokens for repository access. |

## Architecture

```text
GitHub PR  (only changed envs/<project>)
        │
        ▼
 Cloud Build plan  ──▶  tfcmt (PR comment)

GitHub tag  (<project>_*)
        │
        ▼
 Cloud Build apply  ──▶  [Approval required]  ──▶  terraform apply
```

More detail: [docs/architecture.md](docs/architecture.md).

## Layout

```text
.
├── cloudbuild/           # Cloud Build pipeline YAML
│   ├── plan.yaml
│   └── apply.yaml
├── platform/             # CI/CD control plane (Terraform)
│   ├── connection.tf     # GitHub App connection / repository
│   ├── iam.tf            # executor / terraform SA + impersonation
│   ├── triggers.tf       # path-filtered plan / tag apply (+ approval)
│   ├── project-list.tf   # workload project catalog (demo IDs OK)
│   └── locals.tf         # derived locals from enabled_envs
├── envs/                 # sample workloads
│   ├── dev/
│   └── prd/
└── docs/
```

## Quick start

1. Prepare a control project and workload projects in GCP.
2. Install a GitHub App and store the OAuth token in Secret Manager.
3. Copy `platform/terraform.tfvars.example` → `terraform.tfvars`.
4. Set `enabled_envs = ["dev"]` and apply the platform stack.
5. Open a PR that changes only one `envs/...` path → only that project’s plan runs.
6. Push a tag like `demo-app-dev_v1.0.0` → click **Approve** in Cloud Build → apply runs.

```bash
cd platform
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars
terraform init
terraform plan
```

## Known limitations

Remaining production gaps (WIF → GitHub Actions, finer SA least privilege, plan artifact promotion, and more) are tracked in [docs/known-limitations.md](docs/known-limitations.md).

## Topics

`gcp` · `terraform` · `cloud-build` · `github-app` · `cicd` · `iam` · `impersonation`
