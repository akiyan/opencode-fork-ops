#!/usr/bin/env bash
set -euo pipefail
ops_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
source_dir=${SOURCE_DIR:-"$ops_dir/../opencode"}
[[ $# == 1 && $1 != -* ]] || { echo 'Usage: propose-update.sh <upstream-tag-or-SHA>' >&2; exit 1; }
"$ops_dir/scripts/verify.sh"
fork_commit=$(git -C "$source_dir" rev-parse HEAD)
candidate="candidate-$(date -u +%Y%m%d%H%M%S)"
git -C "$source_dir" fetch https://github.com/anomalyco/opencode.git "$1"
new_base=$(git -C "$source_dir" rev-parse FETCH_HEAD)
git -C "$source_dir" switch -c "$candidate" "$new_base"
git -C "$source_dir" cherry-pick "$fork_commit"
printf 'Candidate %s: upstream %s + %s\nRun checks before editing the lock or publishing.\n' "$candidate" "$new_base" "$(git -C "$source_dir" rev-parse HEAD)"
