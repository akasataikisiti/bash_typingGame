#+ プロジェクト生成プロンプト（Bash タイピングゲーム）

以下の要件で、ゼロからリポジトリを作成してください。最終的に `bash typing.sh` で実行でき、`source typing.sh; typingGame` でも同等に動作すること。

## タスク概要
- ターミナルで動く Bash 製タイピングゲームを実装。
- UX: ミスタイプ時のビープ/赤メッセージ、進捗/統計のライブ表示、終了時サマリ、Ctrl+C 中断対応。
- 実行形態: 直接実行と関数実行の両対応（関数はシェル状態を汚さない）。

## 成果物と構成
- `typing.sh`: 本体（関数 `typingGame` 入口、内部に `typing_play_word`）。
- `assets/words.txt`: デフォルト単語リスト（1行1語）。
- `tests/typing.bats`: Bats テスト。
- `Makefile`: `run`, `lint`, `fmt`, `fmt-check`, `test`。
- `.github/workflows/ci.yml`: shellcheck/shfmt/bats を実行する CI。
- `README.md`: 使い方（関数/スクリプト、オプション、環境変数、開発手順）。
- `AGENTS.md`: 簡潔な貢献ガイド（既存要件に準拠）。

## 実装要件
- Bash 4+。`set -Eeuo pipefail` と安全な `IFS` を関数内で設定し、終了時に元へ復元。
- トラップ: `EXIT` は色/カーソルのみ復帰、`INT/TERM` は中断処理（ABORT フラグ）後に復帰。
- ANSI 制御: 部分再描画（入力/メッセージ/ステータスの3行）。`printf` を使用。
- オプション（関数/スクリプト共通）:
  - `-f FILE`: 単語ファイル（1行1語）。`CONTENT` より優先。
  - `-c NUM`: 出題数を制限（正の整数）。
  - `-r`: 出題シャッフル（`shuf` があれば使用）。
- 入力源の優先度: `-f` > `CONTENT` > `WORDS_FILE`/`assets/words.txt` > 内蔵配列。
- 統計: 正打数、総打鍵、目標総文字、経過秒、正確性%、WPM を表示。

## テスト要件（Bats）
- 単語1つ/誤入力混在/複数語の成功。
- `WORDS_FILE` 読み込み、`-f` が `CONTENT` を上書き、`-c` 制限、`-r` で重複語でも完了。
- 関数モード実行（`source`→`typingGame -c 1`）。
- 「完了しました」メッセージの出力確認。

## 開発便利ツール
- Lint: `shellcheck typing.sh`
- Format: `shfmt -i 2 -ci -w typing.sh`
- Makefile に `run/lint/fmt/fmt-check/test` を用意。
- CI: Ubuntu で apt で `shellcheck shfmt bats` を入れ、Make タスクを実行。

## 受け入れ基準
- `make fmt-check && make lint && make test` がローカルで成功。
- 直接実行と関数実行で等価に動作。Ctrl+C 中断時にサマリと「中断しました」表示。
- README と AGENTS に手順と規約が簡潔に記載。
