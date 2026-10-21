#!/usr/bin/env bash
set -euo pipefail
ops_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
result=$(mktemp)
trap 'rm -f -- "$result"' EXIT
gh api 'repos/akiyan/opencode/compare/anomalyco:dev...akiyan' > "$result"
python3 - "$ops_dir/config/source.lock.json" "$result" <<'PY'
import json,sys
lock=json.load(open(sys.argv[1])); comparison=json.load(open(sys.argv[2]))
if comparison['ahead_by'] != 1 or len(comparison['commits']) != 1:
    raise SystemExit('Expected exactly one commit ahead of upstream dev')
if comparison['commits'][0]['sha'] != lock['fork_commit']:
    raise SystemExit('Published branch does not match source.lock.json')
print(f"akiyan vs upstream dev: ahead {comparison['ahead_by']}, behind {comparison['behind_by']}")
PY
