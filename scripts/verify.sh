#!/usr/bin/env bash
set -euo pipefail
ops_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
source_dir=${SOURCE_DIR:-"$ops_dir/../opencode"}
readarray -t locked < <(python3 - "$ops_dir/config/source.lock.json" <<'PY'
import json, sys
lock = json.load(open(sys.argv[1]))
print(lock['upstream_commit'])
print(lock['fork_commit'])
PY
)
[[ ${#locked[@]} == 2 && ${locked[0]} =~ ^[0-9a-f]{40}$ && ${locked[1]} =~ ^[0-9a-f]{40}$ ]] || { echo 'Invalid source lock' >&2; exit 1; }
[[ $(git -C "$source_dir" rev-parse HEAD) == "${locked[1]}" ]] || { echo 'HEAD does not match fork_commit' >&2; exit 1; }
[[ $(git -C "$source_dir" rev-parse HEAD^) == "${locked[0]}" ]] || { echo 'The fork must be exactly one commit above upstream_commit' >&2; exit 1; }
[[ -z $(git -C "$source_dir" status --porcelain) ]] || { echo 'Source worktree must be clean' >&2; exit 1; }
printf 'Verified upstream %s + one fork commit %s\n' "${locked[0]}" "${locked[1]}"
