#!/bin/sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
installer=$repo_root/scripts/scaffolding
tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/scaffolding-test.XXXXXX")
trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

fail() { printf '%s\n' "FAIL: $*" >&2; exit 1; }
assert_absent() { [ ! -e "$1" ] && [ ! -L "$1" ] || fail "expected absent: $1"; }
assert_link_to() { [ -L "$1" ] && [ "$(readlink "$1")" = "$2" ] || fail "unexpected link: $1"; }
run() { "$installer" "$@"; }

home=$tmpdir/home
mkdir -p "$home"

# Dry-run is non-mutating; clean apply is idempotent and uninstall restores absence.
run install --home "$home" | grep -q 'PLAN install' || fail 'missing dry-run plan'
assert_absent "$home/.local/state/agent-scaffolding/manifest"
run install --apply --home "$home" >/dev/null
assert_link_to "$home/.codex/AGENTS.md" "$repo_root/AGENTS.md"
assert_link_to "$home/.claude/CLAUDE.md" "$repo_root/CLAUDE.md"
assert_link_to "$home/.gemini/GEMINI.md" "$repo_root/GEMINI.md"
run install --apply --home "$home" | grep -q 'NOOP install' || fail 'install not idempotent'
run status --home "$home" | grep -q 'STATUS managed current' || fail 'bad current status'
run doctor --home "$home" | grep -q 'DOCTOR ok' || fail 'doctor failed healthy install'
run uninstall --apply --home "$home" >/dev/null
assert_absent "$home/.codex/AGENTS.md"
assert_absent "$home/.claude/CLAUDE.md"
assert_absent "$home/.gemini/GEMINI.md"

# Existing state requires explicit migration and is restored exactly.
migrate_home=$tmpdir/migrate-home
mkdir -p "$migrate_home/.codex" "$migrate_home/.gemini"
printf '%s\n' 'keep codex' > "$migrate_home/.codex/AGENTS.md"
chmod 640 "$migrate_home/.codex/AGENTS.md"
ln -s "$tmpdir/foreign-gemini" "$migrate_home/.gemini/GEMINI.md"
if run install --apply --home "$migrate_home" >/dev/null 2>&1; then fail 'migration lacked explicit flag'; fi
run install --migrate-existing --home "$migrate_home" | grep -q 'previous: file' || fail 'migration dry-run omitted prior type'
run install --apply --migrate-existing --home "$migrate_home" >/dev/null
assert_link_to "$migrate_home/.codex/AGENTS.md" "$repo_root/AGENTS.md"
assert_link_to "$migrate_home/.gemini/GEMINI.md" "$repo_root/GEMINI.md"
run uninstall --apply --home "$migrate_home" >/dev/null
[ "$(cat "$migrate_home/.codex/AGENTS.md")" = 'keep codex' ] || fail 'file content not restored'
assert_link_to "$migrate_home/.gemini/GEMINI.md" "$tmpdir/foreign-gemini"
assert_absent "$migrate_home/.claude/CLAUDE.md"

# Broken symlinks are backed up and restored as symlinks.
broken_home=$tmpdir/broken-home
mkdir -p "$broken_home/.codex"
ln -s "$tmpdir/missing-target" "$broken_home/.codex/AGENTS.md"
run install --apply --migrate-existing --home "$broken_home" >/dev/null
run uninstall --apply --home "$broken_home" >/dev/null
assert_link_to "$broken_home/.codex/AGENTS.md" "$tmpdir/missing-target"

# A source SHA change is status drift, not an invalid manifest.
drift_home=$tmpdir/drift-home
mkdir -p "$drift_home"
run install --apply --home "$drift_home" >/dev/null
sed 's/^source_sha=.*/source_sha=0000000000000000000000000000000000000000/' "$drift_home/.local/state/agent-scaffolding/manifest" > "$drift_home/manifest.new"
mv "$drift_home/manifest.new" "$drift_home/.local/state/agent-scaffolding/manifest"
run status --home "$drift_home" | grep -q 'source-sha-changed' || fail 'source drift not reported'

# Injected failure restores every previous state and leaves no manifest.
failure_home=$tmpdir/failure-home
mkdir -p "$failure_home/.codex"
printf '%s\n' 'before failure' > "$failure_home/.codex/AGENTS.md"
if SCAFFOLDING_FAIL_AFTER=1 run install --apply --migrate-existing --home "$failure_home" >/dev/null 2>&1; then fail 'injected failure succeeded'; fi
unset SCAFFOLDING_FAIL_AFTER
[ "$(cat "$failure_home/.codex/AGENTS.md")" = 'before failure' ] || fail 'failure rollback lost file'
assert_absent "$failure_home/.claude/CLAUDE.md"
assert_absent "$failure_home/.local/state/agent-scaffolding/manifest"

# Unsafe HOME and symlinked destination parents are rejected.
if run doctor --home relative >/dev/null 2>&1; then fail 'relative HOME accepted'; fi
if run doctor --home / >/dev/null 2>&1; then fail 'root HOME accepted'; fi
parent_home=$tmpdir/parent-home
outside=$tmpdir/outside
mkdir -p "$parent_home" "$outside"
ln -s "$outside" "$parent_home/.codex"
if run install --apply --migrate-existing --home "$parent_home" >/dev/null 2>&1; then fail 'symlink parent accepted'; fi
assert_absent "$outside/AGENTS.md"

# Doctor reports changed managed links without repairing them.
doctor_home=$tmpdir/doctor-home
mkdir -p "$doctor_home"
run install --apply --home "$doctor_home" >/dev/null
rm "$doctor_home/.gemini/GEMINI.md"
ln -s "$repo_root/missing-gemini" "$doctor_home/.gemini/GEMINI.md"
if run doctor --home "$doctor_home" >/dev/null 2>&1; then fail 'doctor accepted broken managed link'; fi
assert_link_to "$doctor_home/.gemini/GEMINI.md" "$repo_root/missing-gemini"

# --- Per-host agent unit -----------------------------------------------------
# The agent unit installs generated definitions, not symlinks, and keeps its own
# manifest so the instruction unit is never disturbed by it.
agent_home=$tmpdir/agent-home
mkdir -p "$agent_home" "$tmpdir/cfg/agent-scaffolding" "$tmpdir/no-config"
cat > "$tmpdir/cfg/agent-scaffolding/model-map.yaml" <<'EOF'
aliases:
  - id: economy
    model: test-economy
    effort: high
  - id: balanced
    model: test-balanced
    effort: xhigh
  - id: frontier
    model: test-frontier
    effort: xhigh
  - id: critical
    model: test-critical
    effort: max
EOF

# Without a local model map there is nothing safe to install: the example holds
# code names, not model ids.
if HOME=$tmpdir/no-config XDG_CONFIG_HOME= run install --agents --home "$agent_home" >/dev/null 2>&1; then
  fail 'agent install accepted the example model map'
fi

XDG_CONFIG_HOME=$tmpdir/cfg
export XDG_CONFIG_HOME

run install --agents --home "$agent_home" | grep -q 'PLAN install .*/.codex/agents/explorer.toml' || fail 'missing agent dry-run plan'
assert_absent "$agent_home/.codex/agents/explorer.toml"
run install --agents --apply --home "$agent_home" >/dev/null
for name in explorer implementer spec-reviewer quality-reviewer; do
  [ -f "$agent_home/.codex/agents/$name.toml" ] || fail "missing generated codex agent: $name"
  [ -f "$agent_home/.claude/agents/$name.md" ] || fail "missing generated claude agent: $name"
  [ ! -L "$agent_home/.codex/agents/$name.toml" ] || fail "codex agent must be a generated file, not a link: $name"
done
grep -qx 'model = "test-balanced"' "$agent_home/.codex/agents/implementer.toml" || fail 'implementer was not resolved through the local map'
grep -qx 'model: test-frontier' "$agent_home/.claude/agents/quality-reviewer.md" || fail 'quality-reviewer was not resolved through the local map'
run install --agents --apply --home "$agent_home" | grep -q 'NOOP install' || fail 'agent install not idempotent'
run status --agents --home "$agent_home" | grep -q 'STATUS agents managed current' || fail 'bad agent status'
run doctor --agents --home "$agent_home" | grep -q 'DOCTOR ok agents' || fail 'doctor failed a healthy agent unit'

# An edited definition is drift in the destination; a changed map is drift in the
# render. They are different findings and neither is silently repaired.
printf '%s\n' 'tampered' >> "$agent_home/.codex/agents/explorer.toml"
run status --agents --home "$agent_home" | grep -q 'STATUS agents managed destination changed' || fail 'tampered agent definition not reported'
if run doctor --agents --home "$agent_home" >/dev/null 2>&1; then fail 'doctor accepted a tampered agent definition'; fi
"$repo_root/scripts/gen-agents" --host codex --role explorer > "$agent_home/.codex/agents/explorer.toml"
run status --agents --home "$agent_home" | grep -q 'STATUS agents managed current' || fail 'restored agent definition not accepted'
sed 's/test-economy/changed-economy/' "$tmpdir/cfg/agent-scaffolding/model-map.yaml" > "$tmpdir/cfg/agent-scaffolding/map.new"
mv "$tmpdir/cfg/agent-scaffolding/map.new" "$tmpdir/cfg/agent-scaffolding/model-map.yaml"
run status --agents --home "$agent_home" | grep -q 'STATUS agents managed render-changed' || fail 'model map drift not reported'
sed 's/changed-economy/test-economy/' "$tmpdir/cfg/agent-scaffolding/model-map.yaml" > "$tmpdir/cfg/agent-scaffolding/map.new"
mv "$tmpdir/cfg/agent-scaffolding/map.new" "$tmpdir/cfg/agent-scaffolding/model-map.yaml"

# The two units are independent: each has its own manifest and its own revert.
run install --apply --home "$agent_home" >/dev/null
assert_link_to "$agent_home/.codex/AGENTS.md" "$repo_root/AGENTS.md"
run doctor --home "$agent_home" | grep -q 'NOTE agent unit is installed' || fail 'doctor did not name the other unit'
run uninstall --agents --apply --home "$agent_home" >/dev/null
assert_absent "$agent_home/.codex/agents/explorer.toml"
assert_absent "$agent_home/.claude/agents/quality-reviewer.md"
assert_link_to "$agent_home/.codex/AGENTS.md" "$repo_root/AGENTS.md"
run doctor --home "$agent_home" | grep -q 'DOCTOR ok instructions' || fail 'instruction unit disturbed by the agent unit'

# A pre-existing host definition is only replaced with explicit migration, and it
# comes back byte for byte.
agent_migrate=$tmpdir/agent-migrate
mkdir -p "$agent_migrate/.codex/agents"
printf '%s\n' 'keep my own explorer' > "$agent_migrate/.codex/agents/explorer.toml"
if run install --agents --apply --home "$agent_migrate" >/dev/null 2>&1; then fail 'agent migration lacked explicit flag'; fi
run install --agents --apply --migrate-existing --home "$agent_migrate" >/dev/null
grep -qx 'name = "explorer"' "$agent_migrate/.codex/agents/explorer.toml" || fail 'agent definition not generated over the previous file'
run uninstall --agents --apply --home "$agent_migrate" >/dev/null
[ "$(cat "$agent_migrate/.codex/agents/explorer.toml")" = 'keep my own explorer' ] || fail 'previous agent definition not restored'

# Changing the set of canonical roles invalidates an installed agent manifest.
# That must fail loudly and say how to recover, not fail silently.
agent_stale=$tmpdir/agent-stale
mkdir -p "$agent_stale"
run install --agents --apply --home "$agent_stale" >/dev/null
grep -v 'claude-quality-reviewer' "$agent_stale/.local/state/agent-scaffolding/manifest.agents" > "$agent_stale/manifest.new"
mv "$agent_stale/manifest.new" "$agent_stale/.local/state/agent-scaffolding/manifest.agents"
run install --agents --apply --home "$agent_stale" 2>&1 | grep -q 're-run install --agents --apply' \
  || fail 'a stale agent manifest does not explain the recovery'

unset XDG_CONFIG_HOME

printf '%s\n' 'ok - scaffolding installer'
