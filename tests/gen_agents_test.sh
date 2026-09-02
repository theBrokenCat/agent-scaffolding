#!/bin/sh

set -eu

root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
gen=$root/scripts/gen-agents
example_map=$root/settings/schemas/model-map.example.yaml
tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/gen-agents-test.XXXXXX")
trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

fail() { printf '%s\n' "FAIL: $*" >&2; exit 1; }

fixture=$tmpdir/model-map.yaml
cat > "$fixture" <<'EOF'
aliases:
  - id: economy
    model_codex: fixture-economy
    model_claude: fixture-economy-cl
    effort: high
  - id: balanced
    model_codex: fixture-balanced
    model_claude: fixture-balanced-cl
    effort: xhigh
  - id: frontier
    model_codex: fixture-frontier
    model_claude: fixture-frontier-cl
    effort: xhigh
  - id: critical
    model_codex: fixture-critical
    model_claude: fixture-critical-cl
    effort: max
  - id: diagnostic
    model_codex: fixture-diagnostic
    model_claude: fixture-diagnostic-cl
    effort: high
EOF

# The map, not the script, decides the model and effort behind an alias.
resolved=$("$gen" --resolve --host codex --model-map "$fixture")
printf '%s\n' "$resolved" | grep -qx 'balanced|fixture-balanced|xhigh' || fail 'balanced alias not resolved from the map'
resolved_claude=$("$gen" --resolve --host claude --model-map "$fixture")
printf '%s\n' "$resolved_claude" | grep -qx 'balanced|fixture-balanced-cl|xhigh' \
  || fail 'the same alias must resolve to a different id per host'
printf '%s\n' "$resolved" | grep -qx 'critical|fixture-critical|max' || fail 'critical alias not resolved from the map'
printf '%s\n' "$resolved" | grep -qx 'diagnostic|fixture-diagnostic|high' || fail 'diagnostic rung not resolved from the map'

# The example map holds code names, so it can never be installed into a host. This
# is the last-resort behaviour, so it must be checked from a HOME with no local
# map: on a configured machine a real map exists and would mask the assertion.
noconfig=$tmpdir/noconfig
mkdir -p "$noconfig"
( HOME=$noconfig XDG_CONFIG_HOME= "$gen" --map-path ) | grep -q 'model-map.example.yaml' \
  || fail 'example map is not the last resort'
if ( HOME=$noconfig XDG_CONFIG_HOME= "$gen" --host codex --role explorer --require-local-map ) >/dev/null 2>&1; then
  fail 'example map accepted under --require-local-map'
fi

# A local map takes precedence over the example.
mkdir -p "$tmpdir/xdg/agent-scaffolding"
cp "$fixture" "$tmpdir/xdg/agent-scaffolding/model-map.yaml"
XDG_CONFIG_HOME=$tmpdir/xdg "$gen" --map-path | grep -q "$tmpdir/xdg" || fail 'XDG local map not preferred'
XDG_CONFIG_HOME=$tmpdir/xdg "$gen" --host codex --role explorer --require-local-map >/dev/null \
  || fail 'local map rejected under --require-local-map'

# Four canonical roles materialize as one file per (role, state) pair. The states
# are separate files because the host resolves routing from the named agent.
codex_out=$tmpdir/codex
claude_out=$tmpdir/claude
mkdir -p "$codex_out" "$claude_out"
"$gen" --host codex --out "$codex_out" --model-map "$fixture" >/dev/null
"$gen" --host claude --out "$claude_out" --model-map "$fixture" >/dev/null
states='explorer-economy explorer-balanced implementer-economy implementer-balanced
implementer-frontier spec-reviewer-frontier-high spec-reviewer-frontier-xhigh
quality-reviewer-frontier quality-reviewer-critical'
for name in $states; do
  [ -f "$codex_out/$name.toml" ] || fail "missing codex definition for state $name"
  [ -f "$claude_out/$name.md" ] || fail "missing claude definition for state $name"
done
[ "$(ls "$codex_out" | wc -l | tr -d ' ')" -eq 10 ] || fail 'unexpected number of generated codex files'

# The bare `explorer` name survives, pinned to the base state, so the host
# built-in cannot come back and resolve at the host default.
[ -f "$codex_out/explorer.toml" ] || fail 'bare explorer name was dropped'
grep -qx 'model = "fixture-economy"' "$codex_out/explorer.toml" || fail 'bare explorer is not pinned to the base state'
for name in implementer spec-reviewer quality-reviewer; do
  [ ! -f "$codex_out/$name.toml" ] || fail "$name must not emit a bare name: it overrides no built-in"
done

# A generated file is a state, not a fifth role.
grep -q 'not a role of its own' "$codex_out/explorer-balanced.toml" || fail 'state file does not disclaim being a role'
grep -q 'exactly four generic roles' "$codex_out/explorer-balanced.toml" || fail 'state file does not state the role count'

# Escalation is dispatched by name, and each base state names its escalated file.
grep -q 'escalates by dispatching `explorer-balanced`' "$codex_out/explorer-economy.toml" \
  || fail 'base state does not name its escalated state'
grep -q 'escalates by dispatching `quality-reviewer-critical`' "$codex_out/quality-reviewer-frontier.toml" \
  || fail 'quality-reviewer base does not name the critical state'
grep -q 'Never escalate by passing a model or effort' "$codex_out/explorer-economy.toml" \
  || fail 'base state does not forbid escalation by override'
grep -q 'never by overriding model or effort' "$codex_out/quality-reviewer-critical.toml" \
  || fail 'escalated state does not forbid override dispatch'
grep -q 'its base state is `quality-reviewer-frontier`' "$codex_out/quality-reviewer-critical.toml" \
  || fail 'escalated state does not name its base'

# Every state resolves its own pair, including the one the contract only ever
# reaches by escalation.
check_state() {
  name=$1; model=$2; effort=$3
  grep -qx "model = \"$model\"" "$codex_out/$name.toml" || fail "codex $name is not on $model"
  grep -qx "model_reasoning_effort = \"$effort\"" "$codex_out/$name.toml" || fail "codex $name is not at $effort"
  # The Claude file carries the Claude id for the same alias, never the Codex one.
  grep -qx "model: $model-cl" "$claude_out/$name.md" || fail "claude $name is not on $model-cl"
  if grep -qx "model: $model" "$claude_out/$name.md"; then fail "claude $name leaked the codex id"; fi
}
check_state explorer-economy fixture-economy high
check_state explorer-balanced fixture-balanced xhigh
check_state implementer-economy fixture-economy high
check_state implementer-balanced fixture-balanced xhigh
check_state implementer-frontier fixture-frontier xhigh
check_state spec-reviewer-frontier-high fixture-frontier high
check_state spec-reviewer-frontier-xhigh fixture-frontier xhigh
check_state quality-reviewer-frontier fixture-frontier xhigh
check_state quality-reviewer-critical fixture-critical max

# Read-only roles are materialized read-only; the writer is not.
for name in explorer-economy explorer-balanced spec-reviewer-frontier-high quality-reviewer-critical; do
  grep -qx 'tools: Read, Grep, Glob' "$claude_out/$name.md" || fail "claude $name is not restricted to read-only tools"
  grep -q 'Authority: read-only' "$codex_out/$name.toml" || fail "codex $name does not declare read-only authority"
done
for name in implementer-economy implementer-balanced implementer-frontier; do
  if grep -q '^tools:' "$claude_out/$name.md"; then fail "$name must not be tool-restricted"; fi
  grep -q 'Authority: write' "$codex_out/$name.toml" || fail "codex $name does not declare write authority"
done

# The escalation trigger travels with the definition, not just with the contract.
grep -q 'either escalation gate fires' "$codex_out/implementer-balanced.toml" || fail 'implementer escalation trigger not materialized'
grep -q 'Never change your own model or effort' "$claude_out/explorer-economy.md" || fail 'self-escalation is not forbidden in the definition'

# The canonical roles stay consistent with the alias table: a role may only run at
# an effort other than its alias default when it says why.
role_field() {
  awk -v key="$2" '
    NR == 1 && $0 == "---" { inside = 1; next }
    inside && $0 == "---" { exit }
    inside { k = $0; sub(/:.*/, "", k); if (k == key) { v = $0; sub(/^[a-z_]+:[[:space:]]*/, "", v); print v; exit } }
  ' "$1"
}
for role_file in "$root"/agents/roles/*.md; do
  name=$(role_field "$role_file" name)
  alias=$(role_field "$role_file" alias)
  effort=$(role_field "$role_file" effort)
  alias_effort=$("$gen" --resolve --host codex --model-map "$example_map" | awk -F'|' -v a="$alias" '$1 == a { print $3 }')
  [ -n "$alias_effort" ] || fail "role $name uses alias $alias, which the example map does not define"
  if [ "$effort" != "$alias_effort" ] && [ -z "$(role_field "$role_file" effort_override_reason)" ]; then
    fail "role $name overrides the $alias effort without effort_override_reason"
  fi
  case $alias in
    diagnostic) fail "role $name must not default to the diagnostic rung" ;;
  esac
done

# The cheap rung the contract assigns to mechanical work is a real state.
grep -q 'not a role of its own' "$codex_out/implementer-economy.toml" || fail 'implementer-economy is not a materialized state'
grep -q 'Lower rung of the implementer role' "$codex_out/implementer-economy.toml" \
  || fail 'implementer-economy is not described as a lower rung'
grep -q "default state is \`implementer-balanced\`" "$codex_out/implementer-economy.toml" \
  || fail 'implementer-economy does not name the default state'
grep -q "escalated state is \`implementer-frontier\`" "$codex_out/implementer-economy.toml" \
  || fail 'implementer-economy does not name the escalated state'
if grep -q 'Escalated state of the implementer' "$codex_out/implementer-economy.toml"; then
  fail 'a lower rung must not describe itself as escalated'
fi

# A host with no id for an alias stops: nothing borrows another host's id.
partial=$tmpdir/partial-map.yaml
sed '/model_claude/d' "$fixture" > "$partial"
"$gen" --host codex --role explorer-economy --model-map "$partial" >/dev/null \
  || fail 'a map without claude ids must still generate for codex'
if "$gen" --host claude --role explorer-economy --model-map "$partial" >/dev/null 2>&1; then
  fail 'a missing per-host id was silently filled from another host'
fi
"$gen" --host claude --role explorer-economy --model-map "$partial" 2>&1 | grep -q 'model_claude' \
  || fail 'the stop does not name the missing per-host key'

# Unsupported inputs stop instead of guessing.
if "$gen" --host gemini --role explorer >/dev/null 2>&1; then fail 'unsupported host accepted'; fi
if "$gen" --host codex --role security >/dev/null 2>&1; then fail 'unknown role accepted'; fi
if "$gen" --host codex --role quality-reviewer >/dev/null 2>&1; then fail 'a bare role name with no built-in to override was accepted'; fi
if "$gen" --host codex --out "$tmpdir/absent" >/dev/null 2>&1; then fail 'missing output directory accepted'; fi

printf '%s\n' 'ok - gen-agents'
