#!/bin/sh

# The orchestration contract is prose, so its invariants are easy to break by
# editing one file and forgetting the other three. These checks pin the parts
# that must agree across files.

set -eu

root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
failures=0

fail() {
  printf '%s\n' "FAIL: $*" >&2
  failures=$((failures + 1))
}

require() {
  pattern=$1
  file=$2
  grep -Fq "$pattern" "$root/$file" || fail "missing '$pattern' in $file"
}

refute() {
  pattern=$1
  file=$2
  grep -Fq "$pattern" "$root/$file" && fail "stale '$pattern' still in $file" || :
}

# The alias vocabulary is the same everywhere it is named.
for alias in economy balanced frontier critical; do
  require "\`$alias\`" ROUTER.md
  require "\`$alias\`" profiles/README.md
done
require 'selecciona dos cosas **del subagente**: su modelo y su reasoning effort' ROUTER.md
require 'Sol `max`' ROUTER.md
require 'settings/schemas/model-map.example.yaml' ROUTER.md

# Terra is a diagnostic rung, never a default.
require 'dominada en Pareto' ROUTER.md
require 'nunca es el' ROUTER.md
require 'escalon diagnostico' profiles/README.md
require 'diagnostic' settings/schemas/model-map.example.yaml
require 'never a role default' settings/schemas/model-map.example.yaml

# Both escalation gates exist and are stated as semantic, not path-based.
require '### Gates de escalada a la curva Sol' ROUTER.md
require 'Que toca (seam critico)' ROUTER.md
require 'Cuanto dura (horizonte largo)' ROUTER.md
require 'los paths son senal, no decision' ROUTER.md
require 'gates de escalada' agents/README.md

# The concurrency budget replaced the old three-worker cap, in every file that
# states a limit.
for file in AGENTS.md agents/README.md policies/README.md; do
  require '8 agentes simultaneos' "$file"
  require '3 writers' "$file"
  require 'readers <= 8 - writers' "$file"
  refute 'maximo tres workers' "$file"
  refute 'lead y tres workers' "$file"
done

# The orchestration protocol lives in the contract, and the registry only points
# at it. The anchor the registry uses must exist.
require '## Orquestacion' agents/README.md
require 'antes de la primera espera' agents/README.md
require 'no** es un wait-for-all atomico' agents/README.md
require 'snapshot congelado' agents/README.md
require 'STOP-early' agents/README.md
require 'Reset del contrato' agents/README.md
require 'SLA de reviewer' agents/README.md
require 'Revision final integrada' agents/README.md
require 'source: "contract:agents/README.md#orquestacion"' skills/registry.yaml
grep -Fq 'skills/orchestration' "$root/skills/registry.yaml" && fail 'orchestration must not be a separate skill' || :
[ ! -d "$root/skills/orchestration" ] || fail 'orchestration must not be a separate skill directory'

# Every role declares its routing, and the two reviewer contradictions stay fixed.
for role_file in "$root"/agents/roles/*.md; do
  name=${role_file##*/}
  for key in name description alias effort escalated_alias escalated_effort escalation_trigger authority; do
    grep -q "^$key:" "$role_file" || fail "role $name is missing frontmatter key $key"
  done
done
require 'This role is pre-implementation only' agents/roles/spec-reviewer.md
require 'Do not run this role over a diff' agents/roles/spec-reviewer.md
require 'it belongs to' agents/roles/spec-reviewer.md
require 'Security is not a separate role' agents/roles/quality-reviewer.md
require 'domain: security' agents/roles/quality-reviewer.md
refute 'Do not use as a substitute for a security specialist' agents/roles/quality-reviewer.md
require 'no existe un quinto rol' agents/README.md

# Relative links between contract documents must resolve.
for doc in $(cd "$root" && git ls-files '*.md'); do
  dir=$(dirname "$root/$doc")
  targets=$(sed -n 's/.*](\([^)#][^)]*\)).*/\1/p' "$root/$doc" | sed 's/#.*//')
  for target in $targets; do
    case $target in
      http*|mailto:*|'') continue ;;
    esac
    [ -e "$dir/$target" ] || fail "broken link in $doc: $target"
  done
done

if [ "$failures" -ne 0 ]; then
  printf '%s\n' "orchestration contract checks failed: $failures" >&2
  exit 1
fi
printf '%s\n' 'ok - orchestration contract'
