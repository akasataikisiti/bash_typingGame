# GitHub Actions ワークフロー運用ガイド（最新版）

## 概要
- ワークフロー: `.github/workflows/ci.yml`
- トリガー: `push`, `pull_request`, `workflow_dispatch`
- 無視パス: `**.md`, `.codex/**`
- 権限: `permissions.contents: read`
- 競合制御: `concurrency` により同一ブランチの古い実行を自動キャンセル

## ジョブ構成
1) Lint（`lint`）
- `ludeeus/action-shellcheck@v2` による ShellCheck 実行
- `mfinelli/setup-shfmt@v2` で `shfmt` セットアップし、`shfmt -i 2 -ci -d typing.sh` を実行
- タイムアウト: 5 分

2) Test（`test`）
- Ubuntu ランナーに `bats` を apt で導入
- `bats --print-output-on-failure -r tests` を直接実行（Docker 非依存）
- タイムアウト: 15 分
- 依存関係: `needs: lint`

## 実行の流れ（CI）
1. コードチェックアウト（`actions/checkout@v4`）
2. Lint（ShellCheck + shfmt のフォーマット差分チェック）
3. Test（Bats を直接実行し、失敗時は出力をそのまま表示）

## ローカル再現手順
- Lint: `make lint`
- Format check: `make fmt-check`
- Test（直接）: `bats -r tests`
- まとめ実行: `make ci`（bats がなければ `./scripts/test-docker.sh -r tests` にフォールバック）

備考
- Docker に依存しないため、CI の安定性が向上。ローカルでも `bats` を入れるだけで再現可能。
- 必要に応じて `./scripts/test-docker.sh` を利用可能（開発者の環境次第）。

## 運用ルール
- テストは `tests/*.bats` に配置し、スクリプト名に対応する命名を推奨（例: `typing.bats`）。
- 端末依存の UI は非TTY 環境で落ちないよう実装済み（`typing.sh` の UI ラッパー）。
- PR チェックポイント:
  - ShellCheck 警告なし
  - shfmt 差分なし
  - Bats の全テスト成功（`bats -r tests`）
  - UI 変更時は端末出力例を PR に添付

## よくあるトラブルと対処
- ShellCheck アクションの失敗: ローカルで `shellcheck typing.sh` を実行し同様の警告を解消。
- shfmt 差分あり: `shfmt -i 2 -ci -w typing.sh` で整形して再コミット。
- Bats の失敗: `bats --print-output-on-failure -r tests` をローカルで実行し、失敗ケースの出力を確認。
- ネットワーク輻輳での apt 失敗: 再実行で解消することが多い。恒常的ならキャッシュ/ミラーの検討。

## 変更・拡張の指針
- Bash バージョン行列（例: 4.4/5.2）の追加で互換性検証を強化。
- 失敗時ログのアーティファクト化（`actions/upload-artifact`）。
- 追加の静的解析（例: `shellharden`）の組み込み。

## pre-push フックの活用
- 目的: push 前にローカルで lint とテストを実行し、CI の失敗を未然に防ぐ。
- 導入: `bash scripts/install-hooks.sh`（`core.hooksPath` を `hooks/` に設定）
- 実行: `git push` のたびに自動実行。
- 挙動:
  - `shellcheck` があれば実行し、エラーで push を中断。
  - `bats` があれば `bats -r tests` を実行（なければ Docker フォールバック）。
  - `shfmt -d` は差分の有無を表示。
- 一時スキップ: `SKIP_PRE_PUSH=1 git push`
