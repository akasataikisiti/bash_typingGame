#+ 実装ステップ分解（コミット粒度ガイド）

以下は、この Bash タイピングゲームをゼロから構築するための段階的な実装プランと、各ステップで作成する推奨コミットの粒度・メッセージ例です。各ステップは小さく独立させ、テスト・Lint・実行確認を挟みます。

## 方針
- 1コミット=1論理変更（機能追加、リファクタ、修正、ドキュメント）
- 実装→最小動作確認→テスト追加→リファクタの順で小さく前進
- 失敗しやすい箇所（端末制御、trap、引数パース）は独立コミットで把握容易に

## ステップ一覧（推奨コミット）

1. 初期セットアップ
- feat: 最小の typing.sh を追加（標準入力から1語の逐次入力）
  - `typing.sh` に MVP（1語、正字のみ前進）
  - 実行確認: `bash typing.sh`

2. Lint/Format/テスト基盤
- chore: Makefile を追加 (run/lint/fmt/test-docker/ci)
  - `make run`, `make lint`, `make fmt`, `make fmt-check`, `make test-docker`, `make ci`
- test: Bats を導入し最小テストを追加（Docker の bats で実行）
  - `tests/typing.bats`（単語1つで成功）

3. 安全設定と移植性
- chore: set -Eeuo pipefail と IFS を導入、printf に統一
  - `typing.sh` で `echo -e/-n` を `printf` に変更
  - `make lint`/`fmt-check` で正常確認

4. ANSI 描画と色付け
- feat(ux): 正字を青、残りを黄で色付け
  - 最初は全画面 `clear` による再描画で OK

5. ミスタイプ時のフィードバック
- feat(ux): 誤入力でビープと期待文字を赤で表示
  - 最小テスト: 誤入力混入でも完了するケース

6. 進捗/統計のライブ表示
- feat(ux): 正打/総打鍵/目標総文字/経過秒/正確性/WPM を表示
  - 実装後に `make run` で目視確認

7. 外部単語リスト
- feat(words): WORDS_FILE（未指定時 assets/words.txt）から 1 行 1 語を読み込み
- test: WORDS_FILE 読み込みテスト

8. シャッフル
- feat(ux): SHUFFLE=1 で出題順をシャッフル（`shuf` があれば）
- test: 重複語（例: `aa aa`）で順序に依存せず完了

9. 関数実行対応（source）
- refactor: `typingGame` 関数を導入し、直接実行時のみ起動する main ガード追加
- chore: set/IFS/trap/cursor を関数内に閉じ、終了時に復元
- test: `source typing.sh; typingGame` で動作

10. オプション実装（-f/-c/-r）
- feat(cli): 関数/スクリプト共通で `-f FILE`/`-c NUM`/`-r` を実装
- test: `-f` が CONTENT を上書き、`-c` で出題数制限、`-r` 重複語で完了

11. Ctrl+C 中断
- feat: INT/TERM を trap して ABORT 終了（サマリと「中断しました」表示）
- test(任意): シグナル送出ラッパーで 130 終了を確認（必要なら）

12. 部分再描画でチラつき低減
- feat(ux): 3行（入力/メッセージ/ステータス）を部分上書き描画
- chore: EXIT で画面をクリアしない（色/カーソルのみ復帰）

13. ドキュメント/ガイド/CI
- docs: README を更新（関数実行、オプション、環境変数、Make、CI）
- docs: AGENTS.md（コーディング規約/テスト/PR）
- ci: GitHub Actions（shellcheck + Docker 上の bats）を追加
- docs: BRANCH_PROTECTION 手順

14. 仕上げ
- chore: 不要ファイル削除、シェルチェッカ警告対応
- test: ケース追加/見直し、`make test` 通過

## 検証コマンド例
- 実行: `bash typing.sh` / `source typing.sh; typingGame`
- 単語指定: `CONTENT="ab cd" bash typing.sh`
- ファイル指定: `bash typing.sh -f assets/words.txt -c 5 -r`
- Lint/Test: `make lint && make test-docker`（フォーマットは任意で `make fmt-check`）

## コミットメッセージ例（抜粋）
- feat: 最小の typing.sh を追加（MVP）
- chore: Makefile を追加 (run/lint/fmt/test)
- test: Bats を導入し最小テストを追加
- chore: set -Eeuo pipefail と IFS を導入、printf に統一
- feat(ux): 誤入力でビープと期待文字を赤で表示
- feat(ux): 進捗表示（正打/打鍵/正確性/WPM）を追加
- feat(words): WORDS_FILE から 1 行 1 語を読み込み
- refactor: 関数 typingGame を導入し main ガード追加
- feat(cli): -f/-c/-r オプションを追加
- feat: Ctrl+C 中断に対応
- feat(ux): 部分再描画でチラつきを軽減
- docs: README/AGENTS を更新
- ci: GitHub Actions を追加

## 注意点
- trap は関数内で設定・復元し、source 実行時に親シェルへ漏らさない
- `echo` ではなく `printf` を使用（`-e/-n` 依存を回避）
- `read -r -s -n 1` の扱いに注意（TTYが必要、CIではパイプで代替）
- 描画は ANSI 非対応端末を想定しすぎない（Linux/macOS を対象）
