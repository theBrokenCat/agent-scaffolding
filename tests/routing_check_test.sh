#!/bin/sh

# routing-check reports the pair each subagent ran on, from the child's own turns.
# A forked rollout replays the parent's history first; that turn_context must not
# be read as the child's. Fixtures only; no Codex needed.

set -eu

root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
check=$root/scripts/routing-check
tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/routing-check-test.XXXXXX")
trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

fail() { printf '%s\n' "FAIL: $*" >&2; exit 1; }

day=$(date +%Y/%m/%d)
sessions=$tmpdir/sessions/$day
agents=$tmpdir/agents
mkdir -p "$sessions" "$agents"
printf 'name = "explorer-economy"\nmodel = "luna"\nmodel_reasoning_effort = "high"\n' > "$agents/explorer-economy.toml"

run() { "$check" --sessions "$tmpdir/sessions" --agents "$agents" > "$tmpdir/out" 2>"$tmpdir/err"; }

# Nothing to check is not a pass: it may be a schema change.
printf '{"ordinal":0,"type":"session_meta","payload":{"id":"parent"}}\n' > "$sessions/parent.jsonl"
rc=0; run || rc=$?
[ "$rc" -eq 3 ] || fail "an empty window must exit 3, got $rc"

# child FILE ROLE FORKED(yes|no) MODEL EFFORT [SECOND_MODEL SECOND_EFFORT]: own turns from ordinal 10.
# A forked child carries the parent's replayed turn_context (sol/xhigh) at ordinal 6.
child() {
  fork=null
  [ "$3" = yes ] && fork='"parent-thread"'
  {
    printf '{"ordinal":0,"type":"session_meta","payload":{"id":"%s","parent_thread_id":"p1","agent_role":"%s","forked_from_id":%s,"subagent_history_start_ordinal":10}}\n' "$1" "$2" "$fork"
    if [ "$3" = yes ]; then
      printf '{"ordinal":1,"type":"session_meta","payload":{"id":"p1"}}\n'
      printf '{"ordinal":6,"type":"turn_context","payload":{"model":"sol","effort":"xhigh"}}\n'
    fi
    printf '{"ordinal":15,"type":"turn_context","payload":{"model":"%s","effort":"%s"}}\n' "$4" "$5"
    [ -z "${6-}" ] || printf '{"ordinal":40,"type":"turn_context","payload":{"model":"%s","effort":"%s"}}\n' "$6" "$7"
  } > "$sessions/$1.jsonl"
}

child ok explorer-economy no luna high
run || fail 'a child on its definition pair failed'
grep -q '^OK	explorer-economy	luna/high	expected luna/high	no-fork' "$tmpdir/out" || fail 'the routed child is not reported OK'
[ "$(wc -l < "$tmpdir/out")" -eq 1 ] || fail 'the parent thread must not be checked'

child forked explorer-economy yes luna high
run || fail 'a forked child on its own pair failed'
grep -q '^OK	explorer-economy	luna/high	expected luna/high	fork' "$tmpdir/out" || fail 'the forked child was read from the replayed parent turn'

# A drift on a later own turn is still a drift.
child multi explorer-economy no luna high sol xhigh
if run; then fail 'a drift on a later turn passed'; fi
grep -q '^MISMATCH	explorer-economy	sol/xhigh	expected luna/high' "$tmpdir/out" || fail 'the later-turn drift is not reported'
rm "$sessions/multi.jsonl"

child drift explorer-economy no luna xhigh
if run; then fail 'a child off its effort passed'; fi
grep -q '^MISMATCH	explorer-economy	luna/xhigh	expected luna/high' "$tmpdir/out" || fail 'the effort drift is not reported'
rm "$sessions/drift.jsonl"

# A fork whose own turns cannot be located is UNKNOWN, never the replayed parent pair.
{
  printf '{"type":"session_meta","payload":{"id":"nostart","parent_thread_id":"p1","agent_role":"explorer-economy","forked_from_id":"p1"}}\n'
  printf '{"type":"turn_context","payload":{"model":"sol","effort":"xhigh"}}\n'
  printf '{"type":"turn_context","payload":{"model":"luna","effort":"high"}}\n'
} > "$sessions/nostart.jsonl"
run || fail 'an unlocatable fork must not fail'
grep -q '^UNKNOWN	explorer-economy	-	expected luna/high	fork	nostart' "$tmpdir/out" || fail 'an unlocatable fork was read from some turn'
rm "$sessions/nostart.jsonl"

# A child detected through source.subagent and with no own turn yet is UNKNOWN.
printf '{"ordinal":0,"type":"session_meta","payload":{"id":"young","agent_role":"explorer-economy","subagent_history_start_ordinal":10,"source":{"subagent":{"thread_spawn":{"parent_thread_id":"p1"}}}}}\n' > "$sessions/young.jsonl"
run || fail 'a child without own turns must not fail'
grep -q '^UNKNOWN	explorer-economy	-	expected luna/high	no-fork	young' "$tmpdir/out" || fail 'a nested-source child was skipped or misread'
rm "$sessions/young.jsonl"

# A non-spawn subagent source (a plain string such as a review thread) is not a child and must not crash.
printf '{"ordinal":0,"type":"session_meta","payload":{"id":"review","source":{"subagent":"review"}}}\n' > "$sessions/review.jsonl"
run || fail 'a string subagent source crashed or failed the check'
if grep -q 'review.jsonl' "$tmpdir/out"; then fail 'a non-spawn subagent source was counted as a child'; fi
rm "$sessions/review.jsonl"

child custom someone-else no luna high
run || fail 'an unknown role must not fail'
grep -q '^UNKNOWN	someone-else' "$tmpdir/out" || fail 'the unknown role is not reported'

# The window excludes older days.
old=$tmpdir/sessions/2000/01/01; mkdir -p "$old"
cp "$sessions/ok.jsonl" "$old/old.jsonl"
run || :
if grep -q 'old.jsonl' "$tmpdir/out"; then fail '--since did not exclude an older day'; fi
if "$check" --sessions "$tmpdir/sessions" --agents "$agents" --since nope >/dev/null 2>&1; then fail 'an invalid --since was accepted'; fi

printf '%s\n' 'ok - routing-check'
