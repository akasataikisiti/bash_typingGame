# bash_keytyping

[![CI](https://github.com/akasataikisiti/bash_typingGame/actions/workflows/ci.yml/badge.svg)](https://github.com/akasataikisiti/bash_typingGame/actions/workflows/ci.yml)

ターミナルで動く Bash 製タイピングゲーム。進捗/統計表示、外部単語リスト、シャッフル、関数実行、CI/テストに対応。

## クイックスタート
- スクリプト実行: `bash typing.sh` または `make run`
- 関数実行: `source ./typing.sh` の後に `typingGame [OPTIONS]`
- 中断: 実行中に `Ctrl+C`（中断メッセージとサマリを表示）

注意（source 実行の安全性）
- `typingGame` は関数内で `set -Eeuo pipefail` を一時的に有効化しますが、終了時に元のシェルオプション（`set +o` の退避値）・`IFS`・`trap` を復元します。`source` 実行後でも、親シェルの設定は変わりません。

## オプション（typingGame / スクリプト共通）
- `-f FILE`: 単語ファイル（1行1語）を使用（`CONTENT` より優先）
- `-c NUM`: 出題数を制限（正の整数）
- `-r`: 出題順をシャッフル（`shuf` 利用可能時）

優先度: `-f` > `CONTENT` > `WORDS_FILE`/`assets/words.txt` > 内蔵リスト

## 環境変数（任意）
- `CONTENT="hello world"`（スペース区切り）
- `WORDS_FILE=assets/words.txt`
- `SHUFFLE=1`

備考
- `SHUFFLE=1` または `-r` 指定時、`shuf` が見つからない環境では順序は維持されます（そのまま実行可能）。

## 例
- 単語ファイルから10問をシャッフル: `bash typing.sh -f assets/words.txt -c 10 -r`
- 関数で5問だけ: `source ./typing.sh; CONTENT="foo bar baz qux quux" typingGame -c 5`

## 開発
- Lint: `make lint`（shellcheck）
- Format（任意）: `make fmt` / `make fmt-check`（shfmt）
- Test（Docker 推奨）: `make test-docker` または `./scripts/test-docker.sh -r tests`
- まとめ実行: `make ci`（lint → Docker+bats）

テストの詳細
- ローカルで直接: `bats -r tests`（Bats を apt などで導入）
- 追加テスト観点の要約は `.codex/TESTS.md` を参照
- 非TTY環境（CIなど）でも安全に動作するよう、カーソル表示/非表示などの制御はTTYでのみ有効化されます

フック（任意）
- pre-push フック有効化: `make hooks-install`
- push 前に lint と Docker テストを自動実行（失敗で push を中断）。

## CI とブランチ保護
- バッジの `OWNER/REPO` を実リポジトリに置換してください。
- GitHub Actions は push/PR 時に Lint（shellcheck）と Test（Docker+bats）を実行します。
- ブランチ保護と CI の詳細は `.codex/branch-protection-and-ci.md` を参照。

## トラブルシューティング（Docker）
- `docker` に接続できない: `docker ps` が sudo なしで実行できるか、`id -nG` に `docker` が含まれるか、`ls -l /var/run/docker.sock` が `root:docker` で `660` か確認
- `DOCKER_HOST` が誤設定されていないか確認（通常は未設定）
- rootless の場合は `systemctl --user status docker` と `DOCKER_HOST=unix:///run/user/$UID/docker.sock`
- 代替: ローカルに Bats を導入して `bats -r tests` を実行

関連
- Issue: README 更新の提案（#1）
