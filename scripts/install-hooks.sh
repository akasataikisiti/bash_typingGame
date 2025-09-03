#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# Set this repository to use hooks/ as core.hooksPath and ensure executables.

main() {
  command -v git >/dev/null 2>&1 || {
    echo "git が必要です" >&2
    exit 127
  }

  local repo_root
  repo_root=$(git rev-parse --show-toplevel)
  cd "$repo_root"

  mkdir -p hooks
  chmod +x hooks/* || true

  # Use repository-local config (not global) to point hooksPath to hooks/
  git config core.hooksPath hooks

  echo "hooks ディレクトリを core.hooksPath に設定しました。"
  echo "有効化完了: pre-push フックが次回の git push で動作します。"
}

main "$@"

