#+ CI 上でのシグナルテスト補助スクリプト案

目的
- CI（非対話環境）で Ctrl+C 相当（SIGINT）中断を再現し、終了コード 130 と「中断しました」メッセージを検証する。

基本方針（2案）
- 案A: バックグラウンド起動→一定時間後に `kill -INT`。PTY なし（最小依存）。
- 案B: `script` コマンドで擬似TTY上で起動→`kill -INT`。より対話的に近い。

補助スクリプト例（作成先の提案: `scripts/sigint_runner.sh`）
```bash
#!/usr/bin/env bash
set -Eeuo pipefail

MODE=${1:-script} # script | function
DELAY=${2:-0.3}   # SIGINT を送るまでの秒数
CONTENT_STR=${3:-"abcdef"}

run_target() {
  case "$MODE" in
    script)
      CONTENT="$CONTENT_STR" bash typing.sh ;;
    function)
      bash -lc 'source typing.sh; CONTENT="'$CONTENT_STR'" typingGame' ;;
    *) echo "unknown MODE: $MODE" >&2; exit 2 ;;
  esac
}

# 案A: PTY なしで実行（最小依存）
run_and_sigint_simple() {
  run_target &
  pid=$!
  sleep "$DELAY"
  kill -INT "$pid" || true
  wait "$pid"
}

# 案B: 擬似TTY上で実行（util-linux の script）
run_and_sigint_with_pty() {
  script -qfc "bash -lc 'CONTENT=$CONTENT_STR bash typing.sh'" /dev/null &
  spid=$!
  # 子プロセス（bash typing.sh）を特定して SIGINT を送る
  child=$(ps --ppid "$spid" -o pid= | awk 'NR==1{print $1}')
  sleep "$DELAY"
  kill -INT "${child:-$spid}" || true
  wait "$spid"
}

case "${USE_PTY:-0}" in
  1) run_and_sigint_with_pty ;;
  *) run_and_sigint_simple ;;
esac
```

Bats テスト例（追加先の提案: `tests/signal.bats`）
```bash
#!/usr/bin/env bats

setup() { cd "$BATS_TEST_DIRNAME/.."; chmod +x scripts/sigint_runner.sh || true; }

@test "SIGINT: script mode exits 130 and prints abort message" {
  run bash -lc 'CONTENT="abcdef" scripts/sigint_runner.sh script 0.2 "abcdef"'
  [ "$status" -eq 130 ]
  [[ "$output" == *"中断しました"* ]]
}

@test "SIGINT: function mode exits 130 and prints abort message" {
  run bash -lc 'scripts/sigint_runner.sh function 0.2 "abcdef"'
  [ "$status" -eq 130 ]
  [[ "$output" == *"中断しました"* ]]
}
```

CI への組み込み
- 既存の GitHub Actions で `make test` に上記 Bats を含めるだけでよい。
- もし `script` が無い場合は `apt-get install -y bsdutils`（Ubuntu では util-linux に同梱）を利用。

注意
- `read -s -n 1` は PTY なしでも動作はするが、`stty` 警告が出ることがある。テストでは無視可。
- 子プロセス特定が CI により異なる場合は `pgrep -P "$spid"` 等に切り替え。
