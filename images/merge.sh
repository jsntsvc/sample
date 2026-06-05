#!/usr/bin/env bash
# =============================================================================
# OmniAI 배포 이미지 복원 — Linux/macOS/Git Bash
#
# 사용:
#   chmod +x merge.sh
#   ./merge.sh                 # omniai-server + rag-pipeline 둘 다 복원
#   ./merge.sh server          # omniai-server 만
#   ./merge.sh worker          # rag-pipeline 만
#
# GitHub 파일당 100MB 제한으로 95MB chunk 로 분할 배포됨.
# 복원 후 docker load 까지 자동 실행.
# =============================================================================
set -euo pipefail
cd "$(dirname "$0")"

target=${1:-all}

merge_and_load() {
  local name="$1"
  local tar="${name}.tar"
  local parts="${name}.tar.part-*"

  if ! ls $parts >/dev/null 2>&1; then
    echo "[skip] no parts for ${name}"
    return
  fi

  echo "[merge] ${name} — combining parts..."
  cat $parts > "$tar"

  echo "[verify] SHA256 check..."
  grep "  ${tar}$" SHA256SUMS | sha256sum -c -

  echo "[docker load] ${tar} ..."
  docker load -i "$tar"

  echo "[clean] remove combined tar (parts kept)"
  rm -f "$tar"
  echo "[done] ${name}"
  echo
}

case "$target" in
  server) merge_and_load omniai-server-latest ;;
  worker) merge_and_load rag-pipeline-latest ;;
  all)
    merge_and_load omniai-server-latest
    merge_and_load rag-pipeline-latest
    ;;
  *) echo "usage: $0 [server|worker|all]"; exit 1 ;;
esac

echo "=== loaded images ==="
docker images | grep -E "omniai/(omniai-server|rag-pipeline)"
