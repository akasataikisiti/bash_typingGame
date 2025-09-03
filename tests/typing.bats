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
