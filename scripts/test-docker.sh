#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# Run Bats tests inside a Docker container without installing Bats locally.
# If Docker daemon is unavailable, falls back to local bats when installed.
# Usage:
#   scripts/test-docker.sh                 # runs `bats tests`
#   scripts/test-docker.sh tests/foo.bats  # run a single test file
#   scripts/test-docker.sh -r tests        # pass options before paths

main() {
  local docker_ok=0
  if command -v docker >/dev/null 2>&1; then
    if docker info >/dev/null 2>&1; then
      docker_ok=1
    fi
  fi

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

  if [[ $docker_ok -eq 1 ]]; then
    # Run as the current user to avoid root-owned artifacts.
    docker run --rm \
      -u "$(id -u)":"$(id -g)" \
      -v "${project_root}:${workdir}" \
      -w "${workdir}" \
      "${image}" "${opts[@]}" "${paths[@]}"
    return
  fi

  # Fallback to local bats if available
  if command -v bats >/dev/null 2>&1; then
    echo "docker が利用できないため、ローカルの bats にフォールバックします。" >&2
    bats "${opts[@]}" "${paths[@]}"
    return
  fi

  # Provide helpful guidance when neither is available
  if command -v docker >/dev/null 2>&1; then
    echo "docker コマンドは見つかりましたが、Docker デーモンに接続できません。" >&2
    echo "- デーモン起動を確認 (例: systemctl status docker)" >&2
    echo "- 権限を確認 (docker グループに所属し再ログイン)" >&2
    echo "- Docker Desktop の起動を確認 (macOS/WSL2)" >&2
    echo "回避策: sudo ./scripts/test-docker.sh ${opts[*]} ${paths[*]} または bats をローカルにインストール" >&2
    exit 126
  else
    echo "docker が必要です。インストール後に再実行してください。bats があればローカル実行も可能です。" >&2
    exit 127
  fi
}

main "$@"
