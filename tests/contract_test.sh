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

require '`ready` solo significa que una indexacion' "$policies"
require '`index_repository` sobre el root actual' "$policies"
require '`persistence=false`' "$policies"
require 'repite la consulta una vez' "$policies"
require 'incluidos cambios sin commit' "$policies"

require '### Frescura de codebase-memory-mcp' "$policies"
# The automatic entry point routes to the canonical on-demand procedure.
require 'policies/README.md#frescura-de-codebase-memory-mcp' "$agents"
require 'policies/README.md#git-worktrees-y-pr' "$agents"
require 'policies/README.md#mantenimiento-de-instrucciones-locales' "$agents"
require 'policies/README.md#mantenimiento-de-outline' "$agents"
require 'Una tarea de cambio autorizada incluye crear/enlazar issue, actualizar refs' "$agents"
require 'crear rama/worktree desde `origin/main`' "$agents"
require '## Git, worktrees y PR' "$policies"
require 'pull --ff-only' "$policies"
require 'git diff --cached' "$policies"
require 'No commit ni push' "$agents"
require 'reviewer-disabled' "$agents"
require 'revision independiente aprobada' "$agents"
require 'conserva trabajo ajeno, evidencia historica' "$agents"
require 'no delegacion anidada' "$agents"
require 'sin fallback silencioso' "$agents"
require 'un enlace no obliga a cargar el documento' "$agents"
require '### Mantenimiento de instrucciones locales' "$policies"
require 'Actualiza `AGENTS.md` y/o `CLAUDE.md`' "$policies"
require 'Antes de escribir, relee la version actual' "$policies"
require 'vuelve a leer y comprueba el resultado' "$policies"
require '`persistence=true`' "$policies"
require '`fast` para refrescos cotidianos' "$policies"
require 'agents/README.md#trabajo-multisesion' "$agents"

printf '%s\n' 'ok - global contract'
