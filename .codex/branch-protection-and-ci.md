# ブランチ保護と CI 設定（実施内容まとめ）

## 目的
- main ブランチに対する安全な開発フローの確立（直接 push の抑制、レビュー ＋ CI 通過を必須化）
- 静的解析・フォーマット・テストを自動化して品質を担保

## 追加・変更点
- GitHub Actions ワークフローを追加: `.github/workflows/ci.yml`
  - ジョブ `lint`: shellcheck による Bash Lint を実行
  - ジョブ `fmt-check`: shfmt のフォーマット差分チェック（`-d`）
  - ジョブ `tests`: Docker 上で Bats テスト（`./scripts/test-docker.sh -r tests`）
- PR テンプレートを追加: `.github/pull_request_template.md`
- GitHub ブランチ保護ルール（main）を設定

## ブランチ保護ルール（main）
- 直接 push 禁止（PR 経由の変更のみ）
- レビュー必須: 最低 1 名の承認
- ステータスチェック必須（必須チェック名）
  - `lint`
  - `fmt-check`
  - `tests`
- 最新の main に追随（strict mode）
- 強制 push / ブランチ削除のブロック

## 実行したコマンド

注: `gh` CLI による設定反映。`OWNER/REPO` は自動解決の `:owner` / `:repo` を使用。

```
# ブランチ保護設定（main）
gh api \
  -X PUT \
  repos/:owner/:repo/branches/main/protection \
  -f required_status_checks.strict=true \
  -F required_status_checks.contexts[]=lint \
  -F required_status_checks.contexts[]=fmt-check \
  -F required_status_checks.contexts[]=tests \
  -f enforce_admins=true \
  -f required_pull_request_reviews.required_approving_review_count=1 \
  -f required_pull_request_reviews.dismiss_stale_reviews=true \
  -f required_pull_request_reviews.require_code_owner_reviews=false \
  -f restrictions=''
```

## 運用メモ
- 以後の開発は `feat/*`, `fix/*`, `chore/*` 等のトピックブランチで作業し、PR を作成してください。
- CI がグリーンになり、レビュワー承認後に main へマージ可能になります。
- CI の内容は Makefile と整合（`lint`, `fmt-check`, `test-docker`）しており、ローカル `make ci` でも概ね再現可能です。

