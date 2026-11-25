#!/usr/bin/env bash
set -euo pipefail

ZERO_SHA="0000000000000000000000000000000000000000"

is_valid_commit() {
  local sha="${1:-}"
  [[ -n "$sha" && "$sha" != "$ZERO_SHA" ]] && git cat-file -e "${sha}^{commit}" 2>/dev/null
}

if is_valid_commit "${BASE_SHA:-}"; then
  git rev-parse "${BASE_SHA}^{commit}"
  exit 0
fi

default_branch="${DEFAULT_BRANCH:-main}"
ref_name="${REF_NAME:-}"

if [[ -n "$default_branch" && "$ref_name" != "$default_branch" ]]; then
  for candidate in "origin/${default_branch}" "${default_branch}"; do
    if git rev-parse --verify "${candidate}^{commit}" >/dev/null 2>&1; then
      merge_base="$(git merge-base "$candidate" HEAD 2>/dev/null || true)"
      if is_valid_commit "$merge_base"; then
        echo "$merge_base"
        exit 0
      fi
    fi
  done
fi

if git rev-parse --verify "HEAD~1^{commit}" >/dev/null 2>&1; then
  git rev-parse "HEAD~1^{commit}"
  exit 0
fi

exit 0
