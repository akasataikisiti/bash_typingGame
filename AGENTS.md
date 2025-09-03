# Repository Guidelines

## プロジェクト構成とモジュール整理
- ルート: `typing.sh` — タイピングゲームのメイン Bash スクリプト。
- `tests/` — Bats テスト（例: `tests/typing.bats`）。
- `assets/` — 任意の単語リストやデータファイル。
- 隠しツール: `.git/`, `.codex/` — 通常は変更不要。

## ビルド・テスト・開発コマンド
- ローカル実行: `bash typing.sh` または `chmod +x typing.sh && ./typing.sh`。
- Lint: `shellcheck typing.sh` — Bash の静的解析。
- フォーマット（任意）: `shfmt -i 2 -ci -w typing.sh` — インデント2スペース。
- テスト（Docker 推奨）:
  - ワンショット: `./scripts/test-docker.sh`。
  - 単一ファイル: `./scripts/test-docker.sh tests/typing.bats`。
  - オプション付与: `./scripts/test-docker.sh -r tests`（Bats はオプション→パスの順）。
  - Compose: `docker compose run --rm test`。
  - 直接実行（参考）: `docker run --rm -v "$PWD":/work -w /work bats/bats:latest -r tests`。

## コーディングスタイルと命名規約
- 対象 Bash 4+、インデント2スペース、タブは使用しない。
- スクリプト先頭: `set -Eeuo pipefail`、`IFS=$'\n\t'` を設定。
- 関数: `lower_snake_case()`、定数: `UPPER_CASE`（`readonly` 推奨）。
- 条件は `[[ ... ]]` を使用、展開は必ず引用。
- 関数内変数は `local` を使い、不要なグローバルを避ける。
- 依存は最小限にし、POSIX フレンドリなユーティリティを優先。

## テスト方針
- フレームワーク: Bats（`tests/*.bats`）。
- 命名: スクリプト名に対応（例: `typing.bats`）。
- カバレッジ: 正常入力、誤タイプ、空入力、完了判定、可能ならタイミング。
- 実行: 提出前に `bats tests` を実行し、終了コードとメッセージを検証。

## コミットとプルリクエスト
- コミット: Conventional Commits（例: `feat: タイプ済み接頭辞をハイライト`, `fix: 空入力を処理`）。
- スコープ: 1コミット=1論理変更。
- PR: 概要、目的、テスト手順（実行コマンド）、UI変更は端末出力/スクショ、関連 Issue を添付。
- CI 推奨: `shellcheck`、`shfmt -d`、`bats` を実行。

## セキュリティと設定のヒント
- 秘密情報はコミットしない。本スクリプトはローカル入力のみを扱う。
- ANSI/VT100 端末を想定。Linux/macOS で確認。
- 移植性を重視し、標準的なシェルツールを優先。
