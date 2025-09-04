# 開発者向けテスト実施ガイド

このドキュメントは、開発者がローカルで効率よくテストを実行・再現するための手順をまとめたものです。

## 前提ツール
- `bats`（テストフレームワーク）
- `shellcheck`（Lint）
- `shfmt`（フォーマット）

Ubuntu 例:
```bash
sudo apt-get update
sudo apt-get install -y bats shellcheck shfmt
```

## 基本コマンド
- すべてのテスト: `bats -r tests`
- 単一ファイル: `bats tests/typing.bats`
- テスト失敗時に出力表示: `bats --print-output-on-failure -r tests`

Make ターゲット:
```bash
make lint        # shellcheck
make fmt-check   # shfmt 差分確認
make ci          # lint + fmt-check + bats（bats 未導入なら Docker にフォールバック）
```

## Docker フォールバック（任意）
ローカルに `bats` がない場合や環境差を最小化したい場合は、Docker 実行を利用できます。

```bash
./scripts/test-docker.sh -r tests
# 単一ファイル
./scripts/test-docker.sh tests/typing.bats
```

備考:
- スクリプト内で Bats の「オプション→パス」の順序を補正しますが、推奨は `-r tests` の順です。
- Docker 接続エラーが出る場合は README のトラブルシューティングを参照。

## テスト観点の参照
どの観点をカバーしているかは `.codex/TESTS.md` を参照してください。正常系/異常系/入力正規化/出題制御/表示/source 安全性などを網羅しています。

## よくある失敗と対策
- ShellCheck 警告: `shellcheck typing.sh` の指摘箇所を修正。
- shfmt 差分: `shfmt -i 2 -ci -w typing.sh` で整形して再実行。
- テストがハング: 入力が不足している可能性。`CONTENT` と入力の対応を見直す（例: `CONTENT="ab cd"` に入力 `abcd`）。
- 非TTY前提: テストは非TTYで走ります。UI制御はTTY時のみ有効化される設計（`typing.sh` の UI ラッパー）。

## source 実行時の注意
`typing.sh` を `source` して `typingGame` を呼び出すテストもあります。関数内で一時的に `set -Eeuo pipefail` を有効化しますが、終了時に元のシェルオプション・`IFS`・`trap` を復元するため、親シェルは汚染されません。

## フック（任意）
push 直前に自動で lint とテストを走らせるには、pre-push フックを導入します。

```bash
make hooks-install
```

一時的にスキップしたい場合は `SKIP_PRE_PUSH=1 git push` を利用してください。

