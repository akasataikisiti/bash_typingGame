# GitHub Issue 運用メモ（作成/クローズ）

このプロジェクトで実施した Issue の作成〜クローズ手順を、`gh`（GitHub CLI）を用いた具体例としてまとめます。

## 前提
- `gh` がインストール済み: `gh --version`
- GitHub 認証済み: `gh auth status`
- このリポジトリの `origin` が GitHub を指す（SSH/HTTPS いずれでも可）

## Issue を作成する

例: README 更新（実行方法・テスト手順・回帰防止の説明）に関する Issue を作成。

```bash
gh issue create \
  --title "READMEの更新: 実行方法・テスト手順・回帰防止の説明を追記" \
  --body-file - <<'EOF'
## 目的
プロジェクトのREADMEを最新状態に更新し、利用者とコントリビューターが迷わず使えるようにします。

## 追記・修正提案
- 実行方法（bash実行 / source 実行）
- オプションと環境変数の優先順位
- テスト手順（Bats / Docker / make ci）
- 回帰防止のポイント（set/IFS/trap の復元）
- 非TTY時の表示制御、Docker トラブルシューティング

## 期待成果
- README の各節を更新し、必要に応じてサンプルや出力例を追加
EOF
```

ポイント:
- `--body-file -` とヒアドキュメントを組み合わせると、改行や箇条書きを含む本文をその場で記述できます。
- 既存テンプレートやフォーム（issue forms）を使う場合は、リポジトリ側の設定に従います。

## Issue にコメントを付ける（任意）

```bash
gh issue comment 1 --body 'README更新の対応コミットを反映しました。問題があれば再オープンしてください。'
```

## Issue をクローズする

コメントを付けながらクローズする例:

```bash
gh issue close 1 \
  -c 'README更新の対応コミット(XXXXXXXX)で反映済みのためクローズします。問題があれば再オープンしてください。'
```

補足:
- PR/コミットの本文に `Fixes #1` / `Closes #1` などを含めると、マージ時に自動クローズできます。
- 誤って閉じた場合は `gh issue reopen 1` で再オープンできます。

## 状態確認と参照

```bash
gh issue list              # 未解決のIssue一覧
gh issue view 1 --web      # 既定ブラウザでIssue表示
gh run watch               # CIの追跡（必要に応じて）
```

## トラブルシューティング
- 認証エラー: `gh auth login` を実行。必要なトークンスコープは `repo` など。
- ネットワーク制限: プロキシ環境では `HTTPS_PROXY` を設定。
- 複数アカウント: `gh auth status -h github.com` でアクティブアカウントを確認。

