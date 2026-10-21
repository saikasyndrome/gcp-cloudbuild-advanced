# 残課題 / 制約

*他の言語: [English](known-limitations.md), [한국어](known-limitations.ko.md)*

この設計を実務に近づけるときに残るギャップです。本リポジトリでは **意図的に文書化のみ** し、実装していません。

## 1. Workload Identity Federation (WIF)

**課題:** GitHub → クラウド認証は WIF（キーレス）が望ましい一方、このスタックは **Cloud Build 中心** のため、GitHub Actions ランナーのように WIF を自然に使いづらいです。

**対応方針:** WIF を本格導入するなら Cloud Build に無理に寄せるより、**GitHub Actions への移行（または併用）** が必要です。

**本リポジトリの状態:** 未実装。キーレス認証を強化する際の必須方向として記録。

## 2. ビルド / executor SA の最小権限

**課題:** デモ IAM はパイプラインを立てやすくするため権限が粗いです（例: ワークロードに Terraform SA `roles/editor`）。

**対応方針:** 実運用ではビルド（executor）SA と terraform SA を **環境・リソース種別ごとに最小権限へ細かく調整** する必要があります（state バケットのみ、必要な API のみ、blanket editor 禁止）。モジュール追加のたびに権限表を見直します。

**本リポジトリの状態:** デモ向けの広いロール。実務では IAM マトリクスの細分化が必要。

## 3. Plan artifact の引き継ぎ

**課題:** Apply ビルドで `terraform plan` を再生成してから apply します。PR でレビューした plan バイナリと apply が固定されていません。

**対応方針:** レビュー済み `tfplan`（Terraform バージョン / lock メタデータ含む）を GCS/artifacts に保存し、タグ + 承認後に **その artifact だけ** apply。

**本リポジトリの状態:** 未実装。

## 4. Policy-as-code / マージゲート

**課題:** 品質ゲートは fmt / validate / TFLint / Trivy までです。OPA/Conftest 等の policy-as-code や CODEOWNERS・必須レビューはこの Terraform の外です。

**対応方針:** 変更統制を強めるなら policy-as-code とブランチ保護を運用モデルに含める。

**本リポジトリの状態:** 未実装。

## 5. Drift の継続的コントロール

**課題:** Apply YAML に apply 直後の drift チェックはありますが、定期 drift ジョブや通知はありません。

**対応方針:** 定期 `terraform plan -detailed-exitcode`（または同等）+ 想定外 drift のアラート。

**本リポジトリの状態:** apply パイプライン内の一回限りチェックのみ。

## まとめ

| 項目 | デモ | 実務の方向 |
|---|---|---|
| CI → GCP 認証 | Cloud Build + SA impersonation | **WIF は GitHub Actions 移行が必要** |
| SA 権限 | 広い（例: editor） | **最小権限への細かい調整** |
| Plan → apply | apply 時に再 plan | **レビュー済み plan artifact 引き継ぎ** |
| Policy / レビュー | lint + scan | Policy-as-code + 必須レビュー |
| Drift | apply 直後のみ | 定期 drift + アラート |
