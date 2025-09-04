#!/usr/bin/env bats

setup() {
  cd "$BATS_TEST_DIRNAME/.."
}

@test "script: single word completes with correct input" {
  run bash -lc 'CONTENT="abc" bash typing.sh <<<"abc"'
  [ "$status" -eq 0 ]
}

@test "script: ignores wrong input before correct sequence" {
  run bash -lc 'CONTENT="abc" bash typing.sh <<<"xabc"'
  [ "$status" -eq 0 ]
}

@test "script: multiple words complete with concatenated input" {
  run bash -lc 'CONTENT="ab cd" bash typing.sh <<<"abcd"'
  [ "$status" -eq 0 ]
}

@test "script: reads words from external file (WORDS_FILE)" {
  run bash -lc '
    tmp=$(mktemp)
    printf "ab\ncd\n" > "$tmp"
    WORDS_FILE="$tmp" bash typing.sh <<<"abcd"'
  [ "$status" -eq 0 ]
}

@test "script: -f overrides CONTENT" {
  run bash -lc '
    tmp=$(mktemp)
    printf "ab\n" > "$tmp"
    CONTENT="zz" bash typing.sh -f "$tmp" <<<"ab"'
  [ "$status" -eq 0 ]
}

@test "script: -c limits number of questions" {
  run bash -lc 'CONTENT="ab cd" bash typing.sh -c 1 <<<"ab"'
  [ "$status" -eq 0 ]
}

@test "script: -r shuffle works with duplicate words" {
  run bash -lc 'CONTENT="aa aa" bash typing.sh -r <<<"aaaa"'
  [ "$status" -eq 0 ]
}

@test "function: runs via typingGame with -c" {
  run bash -lc 'source typing.sh; CONTENT="ab" typingGame -c 1 <<<"ab"'
  [ "$status" -eq 0 ]
}

@test "script: prints completion message" {
  run bash -lc 'CONTENT="ab" bash typing.sh <<<"ab"'
  [ "$status" -eq 0 ]
  [[ "$output" == *"完了しました"* ]]
}

@test "script: invalid option returns 2" {
  run bash -lc 'bash typing.sh -z <<<""'
  [ "$status" -eq 2 ]
  [[ "$output" == *"不正なオプション"* ]]
}

@test "script: -f without argument returns 2" {
  run bash -lc 'bash typing.sh -f <<<""'
  [ "$status" -eq 2 ]
  [[ "$output" == *"には引数が必要です"* ]]
}

@test "script: -c invalid values return 2 (0)" {
  run bash -lc 'CONTENT="ab" bash typing.sh -c 0 <<<""'
  [ "$status" -eq 2 ]
  [[ "$output" == *"-c は正の整数を指定してください"* ]]
}

@test "script: -c invalid values return 2 (non-numeric)" {
  run bash -lc 'CONTENT="ab" bash typing.sh -c x <<<""'
  [ "$status" -eq 2 ]
  [[ "$output" == *"-c は正の整数を指定してください"* ]]
}

@test "script: reads CRLF, comments, and blanks with -f" {
  run bash -lc '
    tmp=$(mktemp)
    printf "ab\r\n#comment\r\n\r\ncd\r\n" > "$tmp"
    bash typing.sh -f "$tmp" <<<"abcd"'
  [ "$status" -eq 0 ]
}

@test "script: -c greater than word count still completes" {
  run bash -lc 'CONTENT="ab cd" bash typing.sh -c 10 <<<"abcd"'
  [ "$status" -eq 0 ]
}

@test "script: SHUFFLE=1 and no shuf still completes" {
  run bash -lc '
    tmpdir=$(mktemp -d)
    # 必要最低限のコマンドだけを PATH に通す（shuf は含めない）
    # sed は typing.sh 内で使う可能性があるためリンクしておく
    if [ -x /usr/bin/sed ]; then ln -s /usr/bin/sed "$tmpdir/sed"; fi
    if [ -x /bin/sed ]; then ln -s /bin/sed "$tmpdir/sed" 2>/dev/null || true; fi
    CONTENT="ab cd" SHUFFLE=1 PATH="$tmpdir" /bin/bash typing.sh <<<"abcd"'
  [ "$status" -eq 0 ]
}

@test "script: shows expected character on mistype" {
  run bash -lc 'CONTENT="ab" bash typing.sh <<<"xab"'
  [ "$status" -eq 0 ]
  [[ "$output" == *"期待: a"* ]]
}

@test "script: prints final status line" {
  run bash -lc 'CONTENT="ab" bash typing.sh <<<"ab"'
  [ "$status" -eq 0 ]
  [[ "$output" == *"単語: 1/1"* ]]
}

@test "function: source does not change set -o" {
  run bash -lc '
    before=$(mktemp); after=$(mktemp)
    set +o >"$before"
    source typing.sh
    CONTENT="ab" typingGame -c 1 <<<"ab"
    set +o >"$after"
    diff -u "$before" "$after"'
  [ "$status" -eq 0 ]
}

@test "function: source restores IFS" {
  run bash -lc '
    pre=$(printf %q "$IFS")
    source typing.sh
    CONTENT="ab" typingGame -c 1 <<<"ab"
    post=$(printf %q "$IFS")
    [ "$pre" = "$post" ]'
  [ "$status" -eq 0 ]
}

@test "script: default words file is used when no inputs" {
  run bash -lc 'bash typing.sh -c 1 <<<"cherry"'
  [ "$status" -eq 0 ]
}

@test "script: does not print cursor show/hide codes in non-TTY" {
  run bash -lc 'CONTENT="ab" bash typing.sh <<<"ab"'
  [ "$status" -eq 0 ]
  [[ "$output" != *"[?25l"* ]]
  [[ "$output" != *"[?25h"* ]]
}
