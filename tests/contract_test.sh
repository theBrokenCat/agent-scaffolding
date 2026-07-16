#!/bin/sh

set -eu

root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
agents=$root/AGENTS.md
policies=$root/policies/README.md

fail() { printf '%s\n' "FAIL: $*" >&2; exit 1; }
require() {
  pattern=$1
  file=$2
  grep -Fq "$pattern" "$file" || fail "missing '$pattern' in ${file#$root/}"
}

require '`ready` solo significa que una indexacion' "$agents"
require '`index_repository` sobre el root actual' "$agents"
require '`persistence=false`' "$agents"
require 'repite la consulta una vez' "$agents"
require 'incluidos cambios sin commit' "$agents"

require '### Frescura de codebase-memory-mcp' "$policies"
require 'Reindexa el root actual con `persistence=false`' "$policies"
require 'no vuelvas a reindexar en el mismo loop' "$policies"
require '`persistence=true`' "$policies"
require '`fast` para refrescos cotidianos' "$policies"

printf '%s\n' 'ok - global contract'
