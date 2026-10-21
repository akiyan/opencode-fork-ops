#!/usr/bin/env bash
set -euo pipefail
ops_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
source_dir=${SOURCE_DIR:-"$ops_dir/../opencode"}
"$ops_dir/scripts/verify.sh"
readarray -t locked < <(python3 - "$ops_dir/config/source.lock.json" <<'PY'
import json, sys
lock=json.load(open(sys.argv[1]))
print(lock['version'])
print(lock['fork_commit'])
PY
)
readarray -t packages < <(find "$source_dir/dist" -maxdepth 1 -name "opencode-${locked[0]}-*.tar.gz" -type f)
[[ ${#packages[@]} == 1 ]] || { echo 'Build exactly one release archive first' >&2; exit 1; }
archive=${packages[0]}
(cd -- "$(dirname -- "$archive")" && sha256sum -c "$(basename -- "$archive").sha256")
notes=$(mktemp)
trap 'rm -f -- "$notes"' EXIT
python3 - "$ops_dir/config/source.lock.json" > "$notes" <<'PY'
import json,sys
v=json.load(open(sys.argv[1]))
print('Web UI の入力欄下にリポジトリとセッション統計を表示する独自版です。\n')
print(f"- Version: `{v['version']}` / channel: `{v['channel']}`")
print(f"- Upstream: `{v['upstream_commit']}`")
print(f"- Fork: `{v['fork_commit']}`")
print('\n[運用手順](https://github.com/akiyan/opencode-fork-ops)を参照してください。')
PY
gh release create "v${locked[0]}" "$archive" "$archive.sha256" --repo akiyan/opencode --target "${locked[1]}" --prerelease --title "OpenCode ${locked[0]}" --notes-file "$notes"
