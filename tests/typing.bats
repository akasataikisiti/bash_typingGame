#!/usr/bin/env bats

setup() {
  cd "$BATS_TEST_DIRNAME/.."
}

@test "single word completes with correct input" {
  run bash -lc 'CONTENT="abc" bash typing.sh <<<"abc"'
  [ "$status" -eq 0 ]
}

@test "ignores wrong input before correct sequence" {
  run bash -lc 'CONTENT="abc" bash typing.sh <<<"xabc"'
  [ "$status" -eq 0 ]
}

@test "multiple words complete with concatenated input" {
  run bash -lc 'CONTENT="ab cd" bash typing.sh <<<"abcd"'
  [ "$status" -eq 0 ]
}

