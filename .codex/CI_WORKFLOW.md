# GitHub Actions ワークフロー運用ガイド

## 概要
- ワークフロー: `.github/workflows/ci.yml`
- トリガー: `push`、`pull_request`
- 実行内容:
  - Lint: `shellcheck` で `typing.sh` を静的解析
  - Format check: `shfmt -d` でフォーマット差分を検出
  - Test: Docker 上の `bats/bats:latest` で `tests/*.bats` を実行

## 実行の流れ（CI）
1. コードをチェックアウト
2. `shellcheck` と `shfmt` を apt で導入
3. テストはローカルに Bats をインストールせず、`./scripts/test-docker.sh -r tests` を実行
   - イメージ: `bats/bats:latest`（Entrypoint が `bats`）

## ローカルでの再現手順
- すべてのテスト: `./scripts/test-docker.sh`
- 単一ファイル: `./scripts/test-docker.sh tests/typing.bats`
- ディレクトリ（再帰）: `./scripts/test-docker.sh -r tests`
- 直接 Docker 例: `docker run --rm -v "$PWD":/work -w /work bats/bats:latest -r tests`
- Compose 例: `docker compose run --rm test`

ヒント
- Bats のオプションは「オプション → パス」の順。スクリプトは順序を補正しますが、推奨順で渡してください。
- `BATS_IMAGE` 環境変数で使用するイメージを上書き可能。

## 運用ルール
- テストは `tests/*.bats` に配置し、スクリプト名に対応する命名を推奨（例: `typing.bats`）。
- 端末依存の UI は非TTY 環境で落ちないよう実装（`typing.sh` に UI ラッパーあり）。
- PR では次を確認:
  - `shellcheck` 警告なし
  - `shfmt -d` で差分なし（`shfmt -i 2 -ci -w typing.sh` で整形）
  - `./scripts/test-docker.sh -r tests` が成功
  - UI 変更時は端末出力を PR に添付

## よくあるトラブルと対処
- 「/work/bats がない」: 余分な `bats` をコマンドに重ねていないか確認（イメージに Entrypoint 済み）。
- 「unbound variable」: `set -u` 下で未初期化の配列が原因。`scripts/test-docker.sh` は初期化済み。
- Docker 未インストール: ローカルは Docker 必須。CI ランナーは対応済み。

## 変更・拡張
- テストの並列化やカバレッジ出力が必要な場合は、別ステップを追加してください。
- 追加の静的解析（例: `shellharden`）もステップ追加で統合可能です。

## pre-push フックの活用
- 目的: push 直前にローカルで lint とテストを実行し、CI の失敗を未然に防ぐ。
- 導入: `bash scripts/install-hooks.sh`（`core.hooksPath` を `hooks/` に設定）
- 実行タイミング: `git push` のたびに自動実行。
- 挙動:
  - `shellcheck` があれば実行し、エラーで push を中断。
  - `docker` があれば `./scripts/test-docker.sh -r tests` を実行し、テスト失敗で push を中断。
  - `shfmt -d` は情報表示のみ（差分があっても push は継続）。
- 一時スキップ: `SKIP_PRE_PUSH=1 git push`
