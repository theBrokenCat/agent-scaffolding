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
    model: fixture-economy
    effort: high
  - id: balanced
    model: fixture-balanced
    effort: xhigh
  - id: frontier
    model: fixture-frontier
    effort: xhigh
  - id: critical
    model: fixture-critical
    effort: max
  - id: diagnostic
    model: fixture-diagnostic
    effort: high
EOF

# The map, not the script, decides the model and effort behind an alias.
resolved=$("$gen" --resolve --model-map "$fixture")
printf '%s\n' "$resolved" | grep -qx 'balanced|fixture-balanced|xhigh' || fail 'balanced alias not resolved from the map'
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

# Every canonical role materializes for both hosts.
codex_out=$tmpdir/codex
claude_out=$tmpdir/claude
mkdir -p "$codex_out" "$claude_out"
"$gen" --host codex --out "$codex_out" --model-map "$fixture" >/dev/null
"$gen" --host claude --out "$claude_out" --model-map "$fixture" >/dev/null
for name in explorer implementer spec-reviewer quality-reviewer; do
  [ -f "$codex_out/$name.toml" ] || fail "missing codex definition for $name"
  [ -f "$claude_out/$name.md" ] || fail "missing claude definition for $name"
done

# Alias assignment per role is the contract's, and both hosts must agree on it.
check_pair() {
  name=$1
  model=$2
  effort=$3
  grep -qx "model = \"$model\"" "$codex_out/$name.toml" || fail "codex $name is not on $model"
  grep -qx "model_reasoning_effort = \"$effort\"" "$codex_out/$name.toml" || fail "codex $name is not at effort $effort"
  grep -qx "model: $model" "$claude_out/$name.md" || fail "claude $name is not on $model"
  grep -q "reasoning effort $effort" "$claude_out/$name.md" || fail "claude $name does not state effort $effort"
}
check_pair explorer fixture-economy high
check_pair implementer fixture-balanced xhigh
check_pair spec-reviewer fixture-frontier high
check_pair quality-reviewer fixture-frontier xhigh
if grep -qx 'model_reasoning_effort = "max"' "$codex_out/quality-reviewer.toml"; then
  fail 'quality-reviewer must default to frontier, not critical'
fi

# Read-only roles are materialized read-only; the writer is not.
for name in explorer spec-reviewer quality-reviewer; do
  grep -qx 'tools: Read, Grep, Glob' "$claude_out/$name.md" || fail "claude $name is not restricted to read-only tools"
  grep -q 'Authority: read-only' "$codex_out/$name.toml" || fail "codex $name does not declare read-only authority"
done
if grep -q '^tools:' "$claude_out/implementer.md"; then fail 'implementer must not be tool-restricted'; fi
grep -q 'Authority: write' "$codex_out/implementer.toml" || fail 'codex implementer does not declare write authority'

# The escalation trigger travels with the definition, not just with the contract.
grep -q 'either escalation gate fires' "$codex_out/implementer.toml" || fail 'implementer escalation trigger not materialized'
grep -q 're-dispatches at `frontier`' "$codex_out/implementer.toml" || fail 'implementer escalation target not materialized'
grep -q 're-dispatches at `critical`' "$claude_out/quality-reviewer.md" || fail 'quality-reviewer escalation target not materialized'
grep -q 'Never change your own model or effort' "$claude_out/explorer.md" || fail 'self-escalation is not forbidden in the definition'

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
  alias_effort=$("$gen" --resolve --model-map "$example_map" | awk -F'|' -v a="$alias" '$1 == a { print $3 }')
  [ -n "$alias_effort" ] || fail "role $name uses alias $alias, which the example map does not define"
  if [ "$effort" != "$alias_effort" ] && [ -z "$(role_field "$role_file" effort_override_reason)" ]; then
    fail "role $name overrides the $alias effort without effort_override_reason"
  fi
  case $alias in
    diagnostic) fail "role $name must not default to the diagnostic rung" ;;
  esac
done

# Unsupported inputs stop instead of guessing.
if "$gen" --host gemini --role explorer >/dev/null 2>&1; then fail 'unsupported host accepted'; fi
if "$gen" --host codex --role security >/dev/null 2>&1; then fail 'unknown role accepted'; fi
if "$gen" --host codex --out "$tmpdir/absent" >/dev/null 2>&1; then fail 'missing output directory accepted'; fi

printf '%s\n' 'ok - gen-agents'
