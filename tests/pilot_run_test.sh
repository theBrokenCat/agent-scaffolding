#!/bin/sh

set -eu

root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
harness=$root/scripts/pilot-run
report=$root/scripts/pilot-report
tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/pilot-run-test.XXXXXX")
trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

fail() { printf '%s\n' "FAIL: $*" >&2; exit 1; }

mkdir -p "$tmpdir/cfg/agent-scaffolding" "$tmpdir/sessions/2026/09/02" "$tmpdir/run" "$tmpdir/att"
cat > "$tmpdir/cfg/agent-scaffolding/model-map.yaml" <<'EOF'
aliases:
  - id: economy
    model_codex: luna-test
    model_claude: luna-cl
    effort: high
  - id: balanced
    model_codex: luna-test
    model_claude: luna-cl
    effort: xhigh
  - id: frontier
    model_codex: sol-test
    model_claude: sol-cl
    effort: xhigh
  - id: critical
    model_codex: sol-test
    model_claude: sol-cl
    effort: max
EOF
XDG_CONFIG_HOME=$tmpdir/cfg; export XDG_CONFIG_HOME
PILOT_SESSIONS_DIR=$tmpdir/sessions; export PILOT_SESSIONS_DIR
printf 'tarea acotada\n' > "$tmpdir/prompt.txt"

# The fake exec stands in for `codex exec`. The parent it writes is deliberately
# unlike the child: different id, different model, far cheaper. Every confusion
# this harness has actually shipped came from reading the parent, so the fixture
# makes that mistake detectable instead of plausible.
cat > "$tmpdir/fake-exec" <<'EOF'
#!/bin/sh
model=$1
effort=$2
[ "${FAKE_ROUTING-}" = drift ] && { model=drifted-model; effort=low; }
cat <<JSON
{"type":"thread.started","thread_id":"event-id-not-the-rollout-id"}
{"type":"item.completed","item":{"type":"error","message":"Under-development features enabled: chronicle."}}
{"type":"item.completed","item":{"type":"error","message":"loading hooks from both places"}}
{"type":"turn.completed","usage":{"input_tokens":1000,"cached_input_tokens":400,"output_tokens":50}}
JSON
[ "${FAKE_TOOL_FAIL-}" = yes ] && printf '{"type":"item.completed","item":{"type":"error","message":"command exploded"}}\n'
rm -f "$PILOT_SESSIONS_DIR/2026/09/02/rollout-child.jsonl"
printf '{"payload":{"id":"real-parent-id","cwd":"%s","model":"host-default","effort":"xhigh"}}\n' \
  "$FAKE_CWD" > "$PILOT_SESSIONS_DIR/2026/09/02/rollout-parent.jsonl"
rm -f "$PILOT_SESSIONS_DIR/2026/09/02/rollout-sibling.jsonl"
if [ "${FAKE_NO_DISPATCH-}" != yes ]; then
  # A sibling subagent of the SAME parent, different role and different pair.
  # Matching on the parent id alone picks whichever file comes first.
  {
    printf '{"payload":{"thread_source":"subagent","parent_thread_id":"real-parent-id","id":"sibling-id","source":{"subagent":{"thread_spawn":{"agent_role":"explorer-economy"}}}}}\n' 
    printf '{"type":"turn_context","payload":{"model":"sibling-model","effort":"low"}}\n' 
  } > "$PILOT_SESSIONS_DIR/2026/09/02/rollout-sibling.jsonl"
  {
    printf '{"payload":{"thread_source":"subagent","parent_thread_id":"real-parent-id","id":"real-child-id","source":{"subagent":{"thread_spawn":{"agent_role":"%s"}}}}}\n' "$AGENT_TYPE" 
    printf '{"type":"session_meta","payload":{"base_instructions":{"provenance":{"model":"provenance-model"}}}}\n' 
    printf '{"type":"turn_context","payload":{"model":"%s","effort":"%s"}}\n' "$model" "$effort" 
    printf '{"payload":{"info":{"last_token_usage":{"input_tokens":300000,"cached_input_tokens":100000,"output_tokens":1000}}}}\n' 
    printf '{"payload":{"info":{"total_token_usage":{"input_tokens":300000,"cached_input_tokens":100000,"output_tokens":1000,"reasoning_output_tokens":400}}}}\n' 
  } > "$PILOT_SESSIONS_DIR/2026/09/02/rollout-child.jsonl"
fi
EOF
chmod +x "$tmpdir/fake-exec"
PILOT_EXEC=$tmpdir/fake-exec; export PILOT_EXEC
FAKE_CWD=$tmpdir/run; export FAKE_CWD

run_dispatch() {
  AGENT_TYPE="implementer-$2"; export AGENT_TYPE
  "$harness" dispatch --task "$1" --block b --arm "$2" --agent-type "implementer-$2" \
    --prompt "$tmpdir/prompt.txt" --attempts "$tmpdir/att" --kind "${3:-implementation}" \
    --attempt "${4:-1}" --cwd "$FAKE_CWD" --base-sha deadbeef >/dev/null 2>"$tmpdir/warn.txt"
}
art() { printf '%s/%s__%s__%s__%s.json' "$tmpdir/att" "$1" "$2" "${3:-implementation}" "${4:-1}"; }
field() { awk -v k="$2" 'match($0, "\"" k "\":[ ]*\"?[^\",]*") { s = substr($0, RSTART, RLENGTH); sub("\"" k "\":[ ]*\"?", "", s); print s; exit }' "$1"; }

# 1. One artifact per attempt, written once. Nothing appends to a shared file, so
#    two runs cannot interleave and a repeat cannot silently overwrite evidence.
run_dispatch T1 economy
[ -f "$(art T1 economy)" ] || fail 'no per-attempt artifact was written'
if run_dispatch T1 economy 2>/dev/null; then fail 'a second run overwrote an existing artifact'; fi
run_dispatch T1 economy implementation 2
[ -f "$(art T1 economy implementation 2)" ] || fail 'a second attempt needs its own artifact'
[ "$(ls "$tmpdir/att" | wc -l | tr -d ' ')" -eq 2 ] || fail 'artifacts collided'

# 2. The join survives the event id differing from the parent rollout id.
[ "$(field "$(art T1 economy)" parent_thread_id)" = real-parent-id ] \
  || fail 'the join did not use the parent rollout id'
[ "$(field "$(art T1 economy)" child_thread_id)" = real-child-id ] || fail 'the child was not identified'

# 3. Model, effort and usage come from the child, never the parent — and from
#    the right child: a parent can spawn several, and the pair comes from the turn
#    that ran, not from the first model named anywhere in the file.
[ "$(field "$(art T1 economy)" model)" != sibling-model ] || fail 'a sibling subagent was measured' 
[ "$(field "$(art T1 economy)" model)" != provenance-model ] || fail 'a provenance model was measured' 
[ "$(field "$(art T1 economy)" model)" = luna-test ] || fail 'model was not read from the child'
if [ "$(field "$(art T1 economy)" model)" = host-default ]; then fail 'the parent model was measured'; fi
[ "$(field "$(art T1 economy)" tokens_cached)" = 100000 ] || fail 'cached tokens were not the child ones'
[ "$(field "$(art T1 economy)" tokens_uncached)" = 200000 ] || fail 'uncached tokens were not the child ones'
[ "$(field "$(art T1 economy)" tokens_output)" = 1000 ] || fail 'output tokens were not the child ones'
[ "$(field "$(art T1 economy)" tokens_reasoning)" = 400 ] || fail 'reasoning tokens were not the child ones'

# 4. Tool failures count real failures. Chronicle and duplicate-hook notices are
#    printed on every start: counting them reports a failure on every row.
[ "$(field "$(art T1 economy)" tool_failures)" = 0 ] || fail 'startup warnings were counted as tool failures'
FAKE_TOOL_FAIL=yes run_dispatch T2 economy
[ "$(field "$(art T2 economy)" tool_failures)" = 1 ] || fail 'a real tool failure was not counted'

# 5. Judgement fields start empty and are filled only by the judge and reviewer.
[ -z "$(field "$(art T1 economy)" accepted)" ] || fail 'acceptance was invented at dispatch time'
"$harness" record --attempts "$tmpdir/att" --task T1 --arm economy --kind implementation \
  --attempt 1 --field accepted --value si >/dev/null
[ "$(field "$(art T1 economy)" accepted)" = si ] || fail 'recording acceptance did not work'
if "$harness" record --attempts "$tmpdir/att" --task T1 --arm economy --kind implementation \
  --attempt 1 --field invented --value x >/dev/null 2>&1; then fail 'an unknown field was accepted'; fi

# 6. Every attempt keeps the evidence needed to audit it later.
for key in base_sha prompt_sha256 started_at ended_at wall_seconds parent_thread_id \
  child_thread_id model effort routing_ok cost_usd parent_overhead_tokens; do
  [ -n "$(field "$(art T1 economy)" "$key")" ] || fail "the artifact is missing $key"
done
[ "$(field "$(art T1 economy)" base_sha)" = deadbeef ] || fail 'base sha not recorded'

# Cost uses the frozen prices, per turn, with the >272K surcharge, and never
# charges reasoning twice: output already contains it.
#   fresh 200000 -> 0.2*0.2*2 = 0.08 ; cached 100000 -> 0.1*0.02*2 = 0.004
#   output 1000 -> 0.001*1.2*1.5 = 0.0018     total = 0.0858
cost=$(field "$(art T1 economy)" cost_usd)
[ "$cost" = 0.0858 ] || fail "frozen-price cost is wrong: got $cost, expected 0.0858"
# The same usage on the Sol curve must cost far more, or the curves are not
# being distinguished at all.
run_dispatch T3 frontier
sol=$(field "$(art T3 frontier)" cost_usd)
awk -v a="$sol" -v b="$cost" 'BEGIN { exit !(a > b * 10) }' || fail 'the Sol curve is not priced above Luna'

# The parent's own usage is kept, separately, as experiment overhead.
[ -n "$(field "$(art T1 economy)" parent_overhead_tokens)" ] || fail 'parent overhead was discarded'

# 7. The aggregator refuses incomplete rows and rows that ran off their arm.
FAKE_ROUTING=drift run_dispatch T4 frontier
grep -q 'belongs to another arm' "$tmpdir/warn.txt" || fail 'routing drift was not warned about'
FAKE_NO_DISPATCH=yes run_dispatch T5 economy
[ "$(field "$(art T5 economy)" routing_ok)" = NO-DISPATCH ] || fail 'a missing subagent was not flagged'
out=$("$report" "$tmpdir/att")
printf '%s' "$out" | grep -q '^T1	' || fail 'a complete row was dropped from the report'
printf '%s' "$out" | grep -q 'T4.*routing' || fail 'a drifted row was not listed as excluded'
printf '%s' "$out" | grep -q 'T5.*infraestructura' || fail 'a NO-DISPATCH row was not listed as excluded'
printf '%s' "$out" | awk -F'\t' '$1 == "T2" && NF > 10' | grep -q . && fail 'an unjudged row was counted as a result'
printf '%s' "$out" | grep -q 'coste_overhead_usd' || fail 'shared overhead is not reported separately'

# 8. The recorded spend is what enforces the global ceiling, not an estimate.
spent=$("$harness" spent --attempts "$tmpdir/att")
awk -v v="$spent" 'BEGIN { exit !(v > 0) }' || fail 'spend is not accumulated across artifacts'

printf '%s\n' 'ok - pilot harness'
