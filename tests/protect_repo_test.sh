#!/bin/sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
script=$repo_root/scripts/protect-repo
tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/protect-repo-test.XXXXXX")
trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

fail() { printf '%s\n' "FAIL: $*" >&2; exit 1; }

# gh stub: logs every call to GH_LOG and returns canned read output. Any write
# call (-X POST|PATCH|PUT|DELETE) is recorded but performs nothing, so the test
# can prove dry-run mutates nothing.
bindir=$tmpdir/bin
mkdir -p "$bindir"
cat > "$bindir/gh" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >> "$GH_LOG"
case " $* " in
  *' --input '*) cat >/dev/null 2>&1 || : ;;
esac
prev=''; method=GET
for a in "$@"; do
  { [ "$prev" = "-X" ] || [ "$prev" = "--method" ]; } && method=$a
  prev=$a
done
case $method in
  POST|PATCH|PUT|DELETE) exit 0 ;;
esac
case " $* " in
  *rulesets*) exit 0 ;;                                  # no existing ruleset
  *contents/.github/workflows/ci.yml*) exit 1 ;;         # CI absent
  *.default_branch*) printf 'main\n'; exit 0 ;;
  *.allow_auto_merge*) printf 'false\n'; exit 0 ;;
esac
exit 0
STUB
chmod +x "$bindir/gh"
PATH="$bindir:$PATH"
export PATH

GH_LOG=$tmpdir/gh.log
export GH_LOG

run() { : > "$GH_LOG"; "$script" "$@"; }

# Dry-run plans the ruleset and auto-merge and mutates nothing.
out=$(run theBrokenCat/demo)
printf '%s' "$out" | grep -q "PLAN theBrokenCat/demo create ruleset" || fail 'dry-run omitted ruleset plan'
printf '%s' "$out" | grep -q "PLAN theBrokenCat/demo enable auto-merge" || fail 'dry-run omitted auto-merge plan'
printf '%s' "$out" | grep -q "required checks \[tests\]" || fail 'dry-run should require only tests by default'
printf '%s' "$out" | grep -q "CI workflow absent" || fail 'dry-run omitted CI presence report'
if grep -qE ' -X (POST|PATCH|PUT|DELETE)' "$GH_LOG"; then fail 'dry-run performed a mutating gh call'; fi
printf '%s\n' 'PASS: dry-run plans without mutation'

# --with-reviewer adds the reviewer check to the plan.
out=$(run theBrokenCat/demo --with-reviewer)
printf '%s' "$out" | grep -q "required checks \[tests, reviewer\]" || fail 'with-reviewer did not add reviewer check'
printf '%s\n' 'PASS: --with-reviewer requires reviewer check'

# --apply enables auto-merge and creates the ruleset.
out=$(run theBrokenCat/demo --apply)
printf '%s' "$out" | grep -q "APPLY theBrokenCat/demo enabled auto-merge" || fail 'apply did not enable auto-merge'
printf '%s' "$out" | grep -q "APPLY theBrokenCat/demo created ruleset" || fail 'apply did not create ruleset'
grep -qE ' -X PATCH repos/theBrokenCat/demo' "$GH_LOG" || fail 'apply did not PATCH repo for auto-merge'
grep -qE ' -X POST repos/theBrokenCat/demo/rulesets' "$GH_LOG" || fail 'apply did not POST ruleset'
printf '%s\n' 'PASS: apply enables auto-merge and creates ruleset'

# Argument validation.
if run >/dev/null 2>&1; then fail 'missing target was accepted'; fi
if run --all theBrokenCat/demo >/dev/null 2>&1; then fail '--all with explicit repo was accepted'; fi
printf '%s\n' 'PASS: rejects invalid argument combinations'

printf '%s\n' 'ok - protect-repo'
