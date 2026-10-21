# Known limitations

*Other languages: [한국어](known-limitations.ko.md), [日本語](known-limitations.ja.md)*

Gaps that remain if you operate this design closer to production. This repository documents them on purpose; they are not implemented here.

## 1. Workload Identity Federation (WIF)

**Issue:** Keyless auth via WIF is the preferred pattern for GitHub → cloud, but this stack is centered on **Cloud Build**. In that shape, WIF is not a practical fit the way it is for GitHub-hosted runners.

**Implication:** To adopt WIF properly, plan a **migration (or dual-path) to GitHub Actions** (or another runner model that federates with GCP via WIF), instead of stretching Cloud Build into a WIF-first design.

**Status in this repo:** Not implemented. Documented as a required direction for stronger keyless auth.

## 2. Build / executor SA least privilege

**Issue:** Demo IAM is intentionally coarse (for example Terraform SA with `roles/editor` on workload projects) so the pipeline is easy to stand up.

**Implication:** In real operations, the build/executor SA and terraform SA must be **tuned to minimum permissions** per environment and resource type (state bucket only, target APIs only, no blanket editor). Privilege should be reviewed whenever a new module or service is added.

**Status in this repo:** Broad roles for demo. Production needs a finer IAM matrix.

## 3. Plan artifact promotion

**Issue:** Apply regenerates `terraform plan` in the apply build, then applies that file. The binary plan reviewed on the PR is not locked to apply.

**Implication:** Production can store the reviewed `tfplan` (plus Terraform version / lock metadata) in GCS or artifacts, then apply **that same** artifact after tag + approval.

**Status in this repo:** Not implemented.

## 4. Policy-as-code and merge gates

**Issue:** Quality gates stop at fmt / validate / TFLint / Trivy. There is no OPA/Conftest (or similar) policy gate, and GitHub required reviews / CODEOWNERS are outside this Terraform.

**Implication:** For stricter change control, add policy-as-code and branch protection as part of the operating model.

**Status in this repo:** Not implemented.

## 5. Drift detection as an ongoing control

**Issue:** Apply YAML includes a post-apply drift check in the same pipeline, but there is no scheduled drift job or alerting.

**Implication:** Real ops usually add periodic `terraform plan -detailed-exitcode` (or equivalent) with notification on unexpected drift.

**Status in this repo:** One-shot check in apply only.

## Summary

| Topic | Demo | Production direction |
|---|---|---|
| Auth to GCP from CI | Cloud Build + SA impersonation | Prefer **WIF via GitHub Actions migration** |
| SA permissions | Broad (e.g. editor) | **Fine-grained least privilege** |
| Plan → apply | Re-plan on apply | **Promote reviewed plan artifact** |
| Policy / review | Lint + scan | Policy-as-code + required reviews |
| Drift | Post-apply only | Scheduled drift + alerts |
