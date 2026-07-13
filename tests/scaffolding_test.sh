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

printf '%s\n' 'ok - scaffolding installer'
