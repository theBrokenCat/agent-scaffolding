#!/bin/sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
installer=$repo_root/scripts/scaffolding
tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/scaffolding-test.XXXXXX")
tmpdir=$(CDPATH= cd -- "$tmpdir" && pwd -P)
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

# --- Per-host agent unit ----------------------------------------------------
# The agent unit installs generated definitions, not symlinks, and each host has
# its own manifest so a host whose definitions are unusable can be reverted
# without taking down a host whose definitions work.
agent_home=$tmpdir/agent-home
mkdir -p "$agent_home" "$tmpdir/cfg/agent-scaffolding" "$tmpdir/no-config"
cat > "$tmpdir/cfg/agent-scaffolding/model-map.yaml" <<'EOF'
aliases:
  - id: economy
    model_codex: test-economy
    model_claude: test-economy-cl
    effort: high
  - id: balanced
    model_codex: test-balanced
    model_claude: test-balanced-cl
    effort: xhigh
  - id: frontier
    model_codex: test-frontier
    model_claude: test-frontier-cl
    effort: xhigh
  - id: critical
    model_codex: test-critical
    model_claude: test-critical-cl
    effort: max
EOF

# A host must be named: the unit is per host by construction.
if run install --agents --home "$agent_home" >/dev/null 2>&1; then
  fail 'agent install accepted without --host'
fi
if run install --agents --host gemini --home "$agent_home" >/dev/null 2>&1; then
  fail 'agent install accepted an unsupported host'
fi
if run install --host codex --home "$agent_home" >/dev/null 2>&1; then
  fail '--host accepted without --agents'
fi

# Without a local model map there is nothing safe to install: the example holds
# code names, not model ids.
if HOME=$tmpdir/no-config XDG_CONFIG_HOME= run install --agents --host codex --home "$agent_home" >/dev/null 2>&1; then
  fail 'agent install accepted the example model map'
fi

XDG_CONFIG_HOME=$tmpdir/cfg
export XDG_CONFIG_HOME

run install --agents --host codex --home "$agent_home" | grep -q 'PLAN install .*/.codex/agents/explorer.toml' || fail 'missing agent dry-run plan'
if run install --agents --host codex --home "$agent_home" | grep -q '/.claude/'; then
  fail 'codex plan leaked claude destinations'
fi
assert_absent "$agent_home/.codex/agents/explorer.toml"
run install --agents --host codex --apply --home "$agent_home" >/dev/null
# One file per (role, state), plus the bare `explorer` that overrides a built-in.
for name in explorer explorer-economy explorer-balanced implementer-economy \
  implementer-balanced implementer-frontier spec-reviewer-frontier-high \
  spec-reviewer-frontier-xhigh quality-reviewer-frontier quality-reviewer-critical; do
  [ -f "$agent_home/.codex/agents/$name.toml" ] || fail "missing generated codex agent: $name"
  [ ! -L "$agent_home/.codex/agents/$name.toml" ] || fail "codex agent must be a generated file, not a link: $name"
done
assert_absent "$agent_home/.claude/agents/explorer-economy.md"
grep -qx 'model = "test-balanced"' "$agent_home/.codex/agents/implementer-balanced.toml" || fail 'implementer was not resolved through the local map'
grep -qx 'model_reasoning_effort = "max"' "$agent_home/.codex/agents/quality-reviewer-critical.toml" || fail 'critical state was not materialized'
run install --agents --host codex --apply --home "$agent_home" | grep -q 'NOOP install' || fail 'agent install not idempotent'
run status --agents --host codex --home "$agent_home" | grep -q 'STATUS agents codex managed current' || fail 'bad agent status'
run doctor --agents --host codex --home "$agent_home" | grep -q 'DOCTOR ok agents codex' || fail 'doctor failed a healthy agent unit'

# The other host is a separate unit with a separate manifest.
run status --agents --host claude --home "$agent_home" | grep -q 'STATUS agents claude uninstalled' || fail 'claude unit is not independent'
run install --agents --host claude --apply --home "$agent_home" >/dev/null
grep -qx 'model: test-frontier-cl' "$agent_home/.claude/agents/quality-reviewer-frontier.md" || fail 'quality-reviewer was not resolved through the claude side of the local map'
if grep -qx 'model: test-frontier' "$agent_home/.claude/agents/quality-reviewer-frontier.md"; then
  fail 'the claude definition carries the codex model id'
fi
[ -f "$agent_home/.local/state/agent-scaffolding/manifest.agents.codex" ] || fail 'missing codex manifest'
[ -f "$agent_home/.local/state/agent-scaffolding/manifest.agents.claude" ] || fail 'missing claude manifest'

# Reverting one host leaves the other installed. This is the case the runtime
# parity run produced: one host usable, the other returning 404.
run uninstall --agents --host claude --apply --home "$agent_home" >/dev/null
assert_absent "$agent_home/.claude/agents/explorer-economy.md"
run status --agents --host codex --home "$agent_home" | grep -q 'STATUS agents codex managed current' || fail 'reverting claude disturbed codex'

# An edited definition is drift in the destination; a changed map is drift in the
# render. They are different findings and neither is silently repaired.
printf '%s\n' 'tampered' >> "$agent_home/.codex/agents/explorer.toml"
run status --agents --host codex --home "$agent_home" | grep -q 'STATUS agents codex managed destination changed' || fail 'tampered agent definition not reported'
if run doctor --agents --host codex --home "$agent_home" >/dev/null 2>&1; then fail 'doctor accepted a tampered agent definition'; fi
"$repo_root/scripts/gen-agents" --host codex --role explorer > "$agent_home/.codex/agents/explorer.toml"
run status --agents --host codex --home "$agent_home" | grep -q 'STATUS agents codex managed current' || fail 'restored agent definition not accepted'
sed 's/test-economy/changed-economy/' "$tmpdir/cfg/agent-scaffolding/model-map.yaml" > "$tmpdir/cfg/agent-scaffolding/map.new"
mv "$tmpdir/cfg/agent-scaffolding/map.new" "$tmpdir/cfg/agent-scaffolding/model-map.yaml"
run status --agents --host codex --home "$agent_home" | grep -q 'STATUS agents codex managed render-changed' || fail 'model map drift not reported'
sed 's/changed-economy/test-economy/' "$tmpdir/cfg/agent-scaffolding/model-map.yaml" > "$tmpdir/cfg/agent-scaffolding/map.new"
mv "$tmpdir/cfg/agent-scaffolding/map.new" "$tmpdir/cfg/agent-scaffolding/model-map.yaml"

# The units are independent: each has its own manifest and its own revert.
run install --apply --home "$agent_home" >/dev/null
assert_link_to "$agent_home/.codex/AGENTS.md" "$repo_root/AGENTS.md"
run doctor --home "$agent_home" | grep -q 'NOTE agent unit for codex is installed' || fail 'doctor did not name the other unit'
run uninstall --agents --host codex --apply --home "$agent_home" >/dev/null
assert_absent "$agent_home/.codex/agents/explorer-economy.toml"
assert_link_to "$agent_home/.codex/AGENTS.md" "$repo_root/AGENTS.md"
run doctor --home "$agent_home" | grep -q 'DOCTOR ok instructions' || fail 'instruction unit disturbed by the agent unit'

# A pre-existing host definition is only replaced with explicit migration, and it
# comes back byte for byte.
agent_migrate=$tmpdir/agent-migrate
mkdir -p "$agent_migrate/.codex/agents"
printf '%s\n' 'keep my own explorer' > "$agent_migrate/.codex/agents/explorer.toml"
if run install --agents --host codex --apply --home "$agent_migrate" >/dev/null 2>&1; then fail 'agent migration lacked explicit flag'; fi
run install --agents --host codex --apply --migrate-existing --home "$agent_migrate" >/dev/null
grep -qx 'name = "explorer"' "$agent_migrate/.codex/agents/explorer.toml" || fail 'agent definition not generated over the previous file'
run uninstall --agents --host codex --apply --home "$agent_migrate" >/dev/null
[ "$(cat "$agent_migrate/.codex/agents/explorer.toml")" = 'keep my own explorer' ] || fail 'previous agent definition not restored'

# Changing the set of canonical roles invalidates an installed agent manifest.
# That must fail loudly and say how to recover, not fail silently.
agent_stale=$tmpdir/agent-stale
mkdir -p "$agent_stale"
run install --agents --host codex --apply --home "$agent_stale" >/dev/null
grep -v 'codex-quality-reviewer-critical' "$agent_stale/.local/state/agent-scaffolding/manifest.agents.codex" > "$agent_stale/manifest.new"
mv "$agent_stale/manifest.new" "$agent_stale/.local/state/agent-scaffolding/manifest.agents.codex"
run install --agents --host codex --apply --home "$agent_stale" 2>&1 | grep -q 're-run install --agents --host codex --apply' \
  || fail 'a stale agent manifest does not explain the recovery'

# Read-only checks may run from another checkout of this repository. They use
# the recorded canonical checkout for SHA, sources and renders, and say so.
canonical=$tmpdir/'canonical á'
mkdir -p "$canonical"
cp -R "$repo_root/scripts" "$repo_root/agents" "$canonical/"
cp "$repo_root/AGENTS.md" "$repo_root/CLAUDE.md" "$repo_root/GEMINI.md" "$canonical/"
git -C "$canonical" init -q
git -C "$canonical" config user.name 'Scaffolding Test'
git -C "$canonical" config user.email scaffolding-test@example.invalid
git -C "$canonical" add .
git -C "$canonical" commit -qm canonical
canonical_sha=$(git -C "$canonical" rev-parse HEAD)

peer=$tmpdir/'peer "quoted"'
git -C "$canonical" worktree add -qb peer "$peer"
printf '%s\n' '# peer checkout must not supply canonical content' >> "$peer/AGENTS.md"
printf '%s\n' '# peer checkout must not supply canonical renders' >> "$peer/agents/roles/explorer.md"
git -C "$peer" add AGENTS.md agents/roles/explorer.md
git -C "$peer" commit -qm peer
[ "$canonical_sha" != "$(git -C "$peer" rev-parse HEAD)" ] \
  || fail 'peer fixture HEAD does not differ from the canonical checkout'
[ "$(git -C "$canonical" rev-parse --path-format=absolute --git-common-dir)" = \
  "$(git -C "$peer" rev-parse --path-format=absolute --git-common-dir)" ] \
  || fail 'peer fixture does not resolve to the canonical Git common dir'

peer_home=$tmpdir/peer-home
mkdir -p "$peer_home"
"$canonical/scripts/scaffolding" install --apply --home "$peer_home" >/dev/null
"$canonical/scripts/scaffolding" install --agents --host codex --apply --home "$peer_home" >/dev/null
"$canonical/scripts/scaffolding" install --agents --host claude --apply --home "$peer_home" >/dev/null
peer_note="NOTE using canonical installation $canonical from checkout $peer"
for peer_args in \
  "status" "doctor" \
  "status --agents --host codex" "doctor --agents --host codex" \
  "status --agents --host claude" "doctor --agents --host claude"; do
  # shellcheck disable=SC2086
  peer_output=$("$peer/scripts/scaffolding" $peer_args --home "$peer_home" 2>&1) \
    || fail "same-repository checkout rejected for $peer_args: $peer_output"
  case $peer_args in
    status) printf '%s\n' "$peer_output" | grep -Fqx 'STATUS managed current' || fail 'peer instruction status is not current' ;;
    'status --agents --host codex') printf '%s\n' "$peer_output" | grep -Fqx 'STATUS agents codex managed current' || fail 'peer Codex status is not current' ;;
    'status --agents --host claude') printf '%s\n' "$peer_output" | grep -Fqx 'STATUS agents claude managed current' || fail 'peer Claude status is not current' ;;
  esac
  printf '%s\n' "$peer_output" | grep -Fqx "$peer_note" \
    || fail "same-repository checkout note missing for $peer_args"
done
if "$peer/scripts/scaffolding" install --home "$peer_home" >/dev/null 2>&1; then
  fail 'install dry-run redirected to the canonical checkout'
fi
if "$peer/scripts/scaffolding" uninstall --home "$peer_home" >/dev/null 2>&1; then
  fail 'uninstall dry-run redirected to the canonical checkout'
fi

# Identity is checked before an untrusted checkout can run its generator.
foreign=$tmpdir/foreign
cp -R "$peer" "$foreign"
rm "$foreign/.git"
git -C "$foreign" init -q
foreign_marker=$tmpdir/foreign-generator-ran
cat > "$foreign/scripts/gen-agents" <<EOF
#!/bin/sh
touch "$foreign_marker"
exit 1
EOF
chmod +x "$foreign/scripts/gen-agents"
if "$foreign/scripts/scaffolding" doctor --agents --host codex --home "$peer_home" >/dev/null 2>&1; then
  fail 'doctor accepted a different repository'
fi
assert_absent "$foreign_marker"

# Git's repository-local environment must not spoof identity or make a peer's
# HEAD look like the canonical installation's HEAD (for example inside hooks).
for git_variable in GIT_DIR GIT_COMMON_DIR; do
  if env "$git_variable=$canonical/.git" "$foreign/scripts/scaffolding" doctor --agents --host codex --home "$peer_home" >/dev/null 2>&1; then
    fail "foreign repository accepted through $git_variable"
  fi
  assert_absent "$foreign_marker"
done
peer_git_dir=$(git -C "$peer" rev-parse --absolute-git-dir)
peer_output=$(GIT_DIR="$peer_git_dir" "$peer/scripts/scaffolding" status --home "$peer_home") \
  || fail 'peer status failed with inherited Git context'
printf '%s\n' "$peer_output" | grep -Fqx 'STATUS managed current' \
  || fail 'inherited Git context replaced the canonical SHA'

# A matching caller path is not an identity/integrity shortcut. Root tampering
# must be rejected before invoking that peer's generator.
redirected_manifest=$peer_home/.local/state/agent-scaffolding/manifest.agents.codex
cp "$redirected_manifest" "$tmpdir/manifest.saved"
sed "s|^source_root=.*|source_root=$peer|" "$redirected_manifest" > "$tmpdir/manifest.new"
mv "$tmpdir/manifest.new" "$redirected_manifest"
peer_marker=$tmpdir/peer-generator-ran
cp "$peer/scripts/gen-agents" "$tmpdir/peer-generator.saved"
cat > "$peer/scripts/gen-agents" <<EOF
#!/bin/sh
touch "$peer_marker"
exit 1
EOF
chmod +x "$peer/scripts/gen-agents"
if "$peer/scripts/scaffolding" doctor --agents --host codex --home "$peer_home" >/dev/null 2>&1; then
  fail 'doctor accepted a root-inconsistent manifest from its matching caller'
fi
assert_absent "$peer_marker"
cp "$tmpdir/peer-generator.saved" "$peer/scripts/gen-agents"
cp "$tmpdir/manifest.saved" "$redirected_manifest"

# A manufactured gitfile can borrow a common dir without being a registered
# worktree. Even coherent root/source metadata must not select its generator.
spoof=$tmpdir/unregistered
mkdir -p "$spoof"
cp -R "$canonical/scripts" "$canonical/agents" "$spoof/"
cp "$canonical/AGENTS.md" "$canonical/CLAUDE.md" "$canonical/GEMINI.md" "$spoof/"
printf 'gitdir: %s\n' "$canonical/.git" > "$spoof/.git"
if git -C "$canonical" worktree list --porcelain | grep -Fx "worktree $spoof" >/dev/null; then
  fail 'spoof fixture unexpectedly registered as a worktree'
fi
cp "$redirected_manifest" "$tmpdir/manifest.saved"
sed "s|$canonical|$spoof|g" "$redirected_manifest" > "$tmpdir/manifest.new"
mv "$tmpdir/manifest.new" "$redirected_manifest"
spoof_marker=$tmpdir/spoof-generator-ran
cat > "$spoof/scripts/gen-agents" <<EOF
#!/bin/sh
touch "$spoof_marker"
exit 1
EOF
chmod +x "$spoof/scripts/gen-agents"
for caller in "$canonical" "$spoof"; do
  for query in status doctor; do
    if "$caller/scripts/scaffolding" "$query" --agents --host codex --home "$peer_home" >/dev/null 2>&1; then
      fail "$query accepted an unregistered worktree from $caller"
    fi
    assert_absent "$spoof_marker"
  done
done
cp "$tmpdir/manifest.saved" "$redirected_manifest"

# Own-root checks also require a real Git worktree; a directory within a repo
# must not borrow its ancestor's identity through Git discovery.
for non_git in "$tmpdir/non-git-own" "$canonical/nested-copy"; do
  mkdir -p "$non_git"
  cp -R "$canonical/scripts" "$canonical/agents" "$non_git/"
  cp "$canonical/AGENTS.md" "$canonical/CLAUDE.md" "$canonical/GEMINI.md" "$non_git/"
  non_git_home=$tmpdir/home-${non_git##*/}
  mkdir -p "$non_git_home"
  "$non_git/scripts/scaffolding" install --apply --home "$non_git_home" >/dev/null
  for query in status doctor; do
    if "$non_git/scripts/scaffolding" "$query" --home "$non_git_home" >/dev/null 2>&1; then
      fail "$query accepted a non-Git own root: $non_git"
    fi
  done
done

# A missing/non-Git recorded root and corrupt manifest remain invalid.
for bad_root in "$tmpdir/missing-root" "$tmpdir/non-git-root"; do
  bad_home=$tmpdir/bad-home-${bad_root##*/}
  mkdir -p "$bad_home" "$tmpdir/non-git-root"
  "$canonical/scripts/scaffolding" install --apply --home "$bad_home" >/dev/null
  sed "s|^source_root=.*|source_root=$bad_root|" "$bad_home/.local/state/agent-scaffolding/manifest" > "$bad_home/manifest.new"
  mv "$bad_home/manifest.new" "$bad_home/.local/state/agent-scaffolding/manifest"
  if "$peer/scripts/scaffolding" doctor --home "$bad_home" >/dev/null 2>&1; then
    fail "doctor accepted invalid recorded root: $bad_root"
  fi
done
corrupt_home=$tmpdir/corrupt-home
mkdir -p "$corrupt_home"
"$canonical/scripts/scaffolding" install --apply --home "$corrupt_home" >/dev/null
printf '%s\n' corrupt > "$corrupt_home/.local/state/agent-scaffolding/manifest"
if "$peer/scripts/scaffolding" doctor --home "$corrupt_home" >/dev/null 2>&1; then
  fail 'doctor accepted a corrupt manifest'
fi

unset XDG_CONFIG_HOME

printf '%s\n' 'ok - scaffolding installer'
