# gcp-cloudbuild-advanced

*他の言語: [English](../README.md), [한국어](README.ko.md)*

実務に近い Terraform 運用のための GCP Cloud Build CI/CD です。

パスフィルタ付き plan、タグベース apply + 手動承認、トリガーの集約、least-privilege な SA impersonation で、Terraform を安全に運用する構成をまとめています。

## 動作の流れ

| 段階 | トリガー | 動作 |
|---|---|---|
| **Plan** | Pull Request | `envs/<env>/<project>/**` に **変更があるプロジェクトだけ** plan を実行 |
| **Apply** | Tag push (`<project>_.*`) | **Cloud Build の Approve** 後にのみ apply を実行 |

- Plan はパスごとの `included_files` で絞り込むため、変更のないプロジェクトは動きません。
- Apply はタグ push のあと、Cloud Build コンソールの承認ボタンを押すまで進みません。

## 機能と目的

| 機能 | 目的 |
|---|---|
| **パスフィルタ付き PR plan** | リポジトリ全体の plan を避け、変更されたワークロードだけ `terraform plan` を実行してレビュー負荷とノイズを減らします。 |
| **タグベース apply** | レビュー（PR/plan）とデプロイ（tag）を分離します。apply は merge の副作用ではなく、意図したリリース操作です。 |
| **Apply の手動承認** | インフラ変更の前に人の確認を挟みます。タグ push だけでは apply されないようにします。 |
| **トリガーの集約（制御プロジェクト）** | 各ワークロードにトリガーを散らさず、一箇所で CI/CD を管理して監査と責任分界を明確にします。 |
| **Executor SA → Terraform SA impersonation** | ビルド実行主体とインフラ変更主体を分け、ビルドが侵害されたときの影響範囲を抑えます。 |
| **`enabled_envs` による段階的ロールアウト** | まず `dev`、その後 `prd` と広げ、全環境を一度に接続せず安全に拡大します。 |
| **PR への tfcmt コメント** | plan 結果を PR コメントに出し、Cloud Build ログを追わなくてもインフラ差分をレビューできるようにします。 |
| **品質ゲート (fmt / validate / TFLint / Trivy)** | apply 前にフォーマット・構文・よくある Terraform ミス・高深刻度の IaC 指摘を検出します。 |
| **GitHub App 連携** | 個人 PAT に頼らず、Cloud Build の公式 GitHub 連携でリポジトリへアクセスします。 |

## アーキテクチャ

```text
GitHub PR  (変更された envs/<project> のみ)
        │
        ▼
 Cloud Build plan  ──▶  tfcmt (PR comment)

GitHub tag  (<project>_*)
        │
        ▼
 Cloud Build apply  ──▶  [Approval required]  ──▶  terraform apply
```

詳細: [architecture.md](architecture.md)

## ディレクトリ構成

```text
.
├── cloudbuild/           # Cloud Build パイプライン YAML
│   ├── plan.yaml
│   └── apply.yaml
├── platform/             # CI/CD コントロールプレーン (Terraform)
│   ├── connection.tf     # GitHub App connection / repository
│   ├── iam.tf            # executor / terraform SA + impersonation
│   ├── triggers.tf       # パスフィルタ plan / タグ apply (+ 承認)
│   ├── project-list.tf   # ワークロードプロジェクト一覧（デモ ID で可）
│   └── locals.tf         # enabled_envs から派生する locals
├── envs/                 # サンプルワークロード
│   ├── dev/
│   └── prd/
└── docs/
```

## クイックスタート

1. GCP に control / workload プロジェクトを用意します。
2. GitHub App をインストールし、OAuth トークンを Secret Manager に保存します。
3. `platform/terraform.tfvars.example` → `terraform.tfvars` にコピーします。
4. `enabled_envs = ["dev"]` で platform を適用します。
5. `envs/...` の1パスだけ変えた PR を出すと、そのプロジェクトの plan だけが走ります。
6. `demo-app-dev_v1.0.0` のようなタグを push し、Cloud Build で **Approve** すると apply が実行されます。

```bash
cd platform
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars
terraform init
terraform plan
```

## 残課題

Cloud Build では WIF が使いづらく GitHub Actions 移行が必要な点、実運用でのビルド SA 最小権限の細かい調整、plan artifact 引き継ぎなどは [known-limitations.ja.md](known-limitations.ja.md) にまとめています。

## Topics

`gcp` · `terraform` · `cloud-build` · `github-app` · `cicd` · `iam` · `impersonation`
