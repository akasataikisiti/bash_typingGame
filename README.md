# bash_keytyping

[![CI](https://github.com/OWNER/REPO/actions/workflows/ci.yml/badge.svg)](https://github.com/OWNER/REPO/actions/workflows/ci.yml)

ターミナルで動く Bash 製タイピングゲーム。進捗/統計表示、外部単語リスト、シャッフル、関数実行、CI/テストに対応。

## クイックスタート
- スクリプト実行: `bash typing.sh` または `make run`
- 関数実行: `source ./typing.sh` の後に `typingGame [OPTIONS]`
- 中断: 実行中に `Ctrl+C`（中断メッセージとサマリを表示）

## オプション（typingGame / スクリプト共通）
- `-f FILE`: 単語ファイル（1行1語）を使用（`CONTENT` より優先）
- `-c NUM`: 出題数を制限（正の整数）
- `-r`: 出題順をシャッフル（`shuf` 利用可能時）

優先度: `-f` > `CONTENT` > `WORDS_FILE`/`assets/words.txt` > 内蔵リスト

## 環境変数（任意）
- `CONTENT="hello world"`（スペース区切り）
- `WORDS_FILE=assets/words.txt`
- `SHUFFLE=1`

## 例
- 単語ファイルから10問をシャッフル: `bash typing.sh -f assets/words.txt -c 10 -r`
- 関数で5問だけ: `source ./typing.sh; CONTENT="foo bar baz qux quux" typingGame -c 5`

## 開発
- Lint: `make lint`（shellcheck）
- Format: `make fmt` / `make fmt-check`（shfmt）
- Test: `make test`（bats）

## CI とブランチ保護
- バッジの `OWNER/REPO` を実リポジトリに置換してください。
- GitHub Actions は push/PR 時に Lint/Format/Test を実行します。
- ブランチ保護手順は `.github/BRANCH_PROTECTION.md` を参照。
