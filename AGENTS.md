# リポジトリガイドライン

## プロジェクト構成とモジュール整理
- ルート: `typing.sh` — タイピングゲームのメイン Bash スクリプト。
- `tests/` — 任意。Bats テストを配置（例: `tests/typing.bats`）。
- `assets/` — 任意。単語リストやデータファイル。
- 隠しツール: `.git/`, `.codex/`（通常は変更不要）。

## ビルド・テスト・開発コマンド
- ローカル実行: `bash typing.sh` または `chmod +x typing.sh && ./typing.sh`。
- Lint: `shellcheck typing.sh`（ShellCheck をローカルにインストール）。
- フォーマット（任意）: `shfmt -i 2 -ci -w typing.sh`（インデント2スペース）。
- テスト（存在する場合）: `bats tests` または `bats tests/typing.bats`。

## コーディングスタイルと命名規約
- Bash 4+ を対象。インデントは2スペース、タブは使用しない。
- 安全設定: スクリプト先頭に `set -Eeuo pipefail` と `IFS=$'\n\t'`。
- 関数: `lower_snake_case()`。定数: `UPPER_CASE`（例: `ESC`）。
- 条件は `[[ ... ]]` を使用。展開は引用。関数内変数は `local`。
- 定数には `readonly` を推奨。不要なグローバルを避ける。

## テスト方針
- フレームワーク: Bats 推奨。`tests/*.bats` に配置。
- 命名: スクリプト名に対応（例: `tests/typing.bats`）。
- カバレッジ: 主要フローを網羅（正しい入力、誤入力、完了判定）。
- CI 推奨: `shellcheck`、`shfmt -d`、`bats` を PR ごとに実行。

## コミットとプルリクエスト
- コミット: Conventional Commits を推奨（例: `feat: タイプ済み接頭辞に色付け`, `fix: 空入力を処理`）。
- 1コミット=1論理変更。小さく保つ。
- PR: 概要、目的、テスト手順（実行したコマンド）、UI変更は端末出力/スクショ、関連 Issue のリンクを含める。

## セキュリティと設定のヒント
- 秘密情報はコミットしない。このスクリプトはローカル入力のみを扱う。
- 端末互換性: ANSI/VT100 シーケンスを前提。Linux/macOS で確認。
- 依存は最小限にし、移植性の高い POSIX フレンドリなユーティリティを優先。
