#!/usr/bin/env bash
set -euo pipefail

BASE=${BASE_REF:-origin/main}

CHANGED=$(git diff --name-only "$BASE"...HEAD | grep -E '\.(swift|c|cpp|mm|metal)$' || true)

if [[ -z "$CHANGED" ]]; then
  echo '^Noop$'
  exit 0
fi

TARGETS=()
while IFS= read -r f; do
  top=$(echo "$f" | awk -F'/' '{print $1}')
  mod=$(echo "$f" | awk -F'/' '{print $2}')
  case "$top" in
    libs) name="$mod" ;;
    apps) name="$mod" ;;
    *)    name="" ;;
  esac
  if [[ -n "${name}" ]]; then
    TARGETS+=("^${name}\.|\b${name}Tests\.")
  fi
done <<< "$CHANGED"

if [[ ${#TARGETS[@]} -eq 0 ]]; then
  echo '.*'
else
  printf '%s\n' "${TARGETS[@]}" | sort -u
fi
