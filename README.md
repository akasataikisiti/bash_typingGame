# bash_keytyping

[![CI](https://github.com/OWNER/REPO/actions/workflows/ci.yml/badge.svg)](https://github.com/OWNER/REPO/actions/workflows/ci.yml)

ターミナルで動くシンプルな Bash 製タイピングゲームです。安全設定、進捗表示、外部単語リスト、テスト、CI を備えています。

## 使い方
- 実行: `bash typing.sh` または `make run`
- 出題上書き: `CONTENT="hello world" bash typing.sh`
- シャッフル: `SHUFFLE=1 bash typing.sh`
- 外部単語リスト: `WORDS_FILE=assets/words.txt bash typing.sh`
- Lint/Format: `make lint` / `make fmt-check`
- テスト: `make test`（bats が必要）

## CI バッジの設定
上のバッジ URL の `OWNER/REPO` を実リポジトリに置き換えてください。
- 例: `https://github.com/yourname/bash_keytyping/actions/workflows/ci.yml/badge.svg`
- クリック先: `https://github.com/yourname/bash_keytyping/actions/workflows/ci.yml`

ブランチ保護の設定手順は `.github/BRANCH_PROTECTION.md` を参照してください。
