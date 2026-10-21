#!/usr/bin/env bash
set -euo pipefail
ops_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
source_dir=${SOURCE_DIR:-"$ops_dir/../opencode"}
"$ops_dir/scripts/verify.sh"
readarray -t locked < <(python3 - "$ops_dir/config/source.lock.json" <<'PY'
import json, sys
lock = json.load(open(sys.argv[1]))
print(lock['version'])
print(lock['channel'])
PY
)
cd -- "$source_dir"
bun install --frozen-lockfile
OPENCODE_VERSION=${locked[0]} OPENCODE_CHANNEL=${locked[1]} bun run packages/cli/script/build.ts --single --skip-install
"$ops_dir/scripts/verify.sh"
mkdir -p "$source_dir/dist"
python3 - "$source_dir" "$ops_dir" "${locked[0]}" <<'PY'
import hashlib, json, pathlib, platform, shutil, sys, tarfile
source, ops = map(pathlib.Path, sys.argv[1:3])
executables = list((source/'packages/cli/dist').glob('*/bin/opencode'))
if len(executables) != 1:
    raise SystemExit(f'Expected exactly one target binary, got {executables}')
exe = executables[0]
version = sys.argv[3]
if any(c not in 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-' for c in version):
    raise SystemExit('Invalid artifact version')
archive = source/'dist'/f'opencode-{version}-{platform.system().lower()}-{platform.machine()}.tar.gz'
with tarfile.open(archive, 'w:gz') as tar:
    tar.add(exe, arcname='opencode')
    tar.add(ops/'config/source.lock.json', arcname='source.lock.json')
archive.with_suffix(archive.suffix+'.sha256').write_text(hashlib.sha256(archive.read_bytes()).hexdigest()+'  '+archive.name+'\n')
shutil.copy2(exe, source/'dist/opencode')
print(archive)
PY
"$source_dir/dist/opencode" --version
