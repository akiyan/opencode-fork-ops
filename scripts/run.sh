#!/usr/bin/env bash
set -euo pipefail
ops_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
runtime_dir=${RUNTIME_DIR:-"$ops_dir/.runtime"}
[[ -x "$ops_dir/dist/opencode" ]] || { echo 'Run scripts/build.sh first' >&2; exit 1; }
mkdir -p "$runtime_dir"/{data,config,state,cache}
chmod 700 "$runtime_dir"
runtime_dir=$(cd -- "$runtime_dir" && pwd)
if [[ -z ${OPENCODE_SERVER_PASSWORD:-} ]]; then
  read -r -s -p 'OpenCode password: ' OPENCODE_SERVER_PASSWORD
  printf '\n'
fi
[[ -n $OPENCODE_SERVER_PASSWORD ]] || { echo 'Password cannot be empty' >&2; exit 1; }
export OPENCODE_SERVER_PASSWORD OPENCODE_DISABLE_AUTOUPDATE=1
export XDG_DATA_HOME="$runtime_dir/data" XDG_CONFIG_HOME="$runtime_dir/config"
export XDG_STATE_HOME="$runtime_dir/state" XDG_CACHE_HOME="$runtime_dir/cache"
# Prevent accidental inheritance of a live database or external config from the invoking shell.
unset OPENCODE_DB OPENCODE_CONFIG OPENCODE_CONFIG_DIR OPENCODE_CONFIG_CONTENT OPENCODE_PASSWORD
exec "$ops_dir/dist/opencode" serve --hostname 127.0.0.1 --port "${PORT:-4496}"
