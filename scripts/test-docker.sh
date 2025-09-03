#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# Run Bats tests inside a Docker container without installing Bats locally.
# Usage:
#   scripts/test-docker.sh                 # runs `bats tests`
#   scripts/test-docker.sh tests/foo.bats  # run a single test file
#   scripts/test-docker.sh -r tests        # pass options before paths

main() {
  command -v docker >/dev/null 2>&1 || {
    echo "docker が必要です。インストール後に再実行してください。" >&2
    exit 127
  }

  local image
  image=${BATS_IMAGE:-bats/bats:latest}

  local project_root workdir
  project_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
  workdir=/work

  # Split args into options (start with '-') and paths (others),
  # since Bats expects options before files/dirs.
  local -a opts=() paths=()
  if [[ $# -gt 0 ]]; then
    for a in "$@"; do
      if [[ $a == -* ]]; then
        opts+=("$a")
      else
        paths+=("$a")
      fi
    done
  fi
  if [[ ${#paths[@]} -eq 0 ]]; then
    paths=(tests)
  fi

  # Run as the current user to avoid root-owned artifacts.
  docker run --rm \
    -u "$(id -u)":"$(id -g)" \
    -v "${project_root}:${workdir}" \
    -w "${workdir}" \
    "${image}" "${opts[@]}" "${paths[@]}"
}

main "$@"
