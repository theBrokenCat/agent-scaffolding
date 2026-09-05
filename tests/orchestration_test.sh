#!/bin/sh

# Pin safety invariants at their canonical owner and the links to that owner.
# These are document checks, not evidence of model performance or runtime behavior.

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
done
require 'selecciona dos cosas **del subagente**: su modelo y su reasoning effort' ROUTER.md
require 'Sol `max`' ROUTER.md
require 'settings/schemas/model-map.example.yaml' ROUTER.md

# Profiles is a compatibility index, not a duplicate routing policy.
require '../ROUTER.md#esfuerzo-modelo-y-mapping-local' profiles/README.md
require '../policies/README.md' profiles/README.md
require 'provisional' ROUTER.md
refute 'dominada en Pareto' ROUTER.md
refute 'dominada en Pareto' profiles/README.md
require 'escalon diagnostico' ROUTER.md
require 'diagnostic' settings/schemas/model-map.example.yaml
require 'never a role default' settings/schemas/model-map.example.yaml

# Both escalation gates exist and are stated as semantic, not path-based.
require '### Gates de escalada a la curva Sol' ROUTER.md
require 'Que toca (seam critico)' ROUTER.md
require 'Razonamiento inseparable' ROUTER.md
require 'no lances implementers' ROUTER.md
require 'multiple steps or missing acceptance alone do not justify escalation' agents/roles/implementer.md
require 'los paths son senal, no decision' ROUTER.md
require 'gates de escalada' agents/README.md

# The concurrency budget replaced the old three-worker cap, in every file that
# states a limit.
for file in AGENTS.md agents/README.md; do
  require '8 agentes simultaneos' "$file"
  require '3 writers' "$file"
  require 'readers <= 8 - writers' "$file"
  refute 'maximo tres workers' "$file"
  refute 'lead y tres workers' "$file"
done
require '../agents/README.md#orquestacion' policies/README.md
require '../AGENTS.md#5-git-github-y-limites' policies/README.md

# The orchestration protocol lives in the contract, and the registry only points
# at it. The anchor the registry uses must exist.
require '## Orquestacion' agents/README.md
require 'antes de la primera espera' agents/README.md
require 'no** es un wait-for-all atomico' agents/README.md
require 'snapshot congelado' agents/README.md
require 'Nunca forkees los turnos del padre' agents/README.md
require 'FALLO' agents/README.md
require 'fork_turns' agents/README.md
require 'agents/README.md#orquestacion' AGENTS.md
require 'La escalada se despacha por nombre, no por override' agents/README.md
require 'Los roles canonicos son **cuatro**' agents/README.md
require 'archivo generado es un estado materializado, no un rol nuevo' agents/README.md
require 'la definicion del archivo gana' agents/README.md
require 'STOP-early' agents/README.md
require 'Reset del contrato' agents/README.md
require 'SLA de reviewer' agents/README.md
require 'Revision final integrada' agents/README.md
require '## Trabajo multisesion' agents/README.md
require 'no es una via' policies/README.md
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
