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
if [ -n "${FAKE_EXEC_COUNT_DIR-}" ]; then
  mkdir "$FAKE_EXEC_COUNT_DIR/$$"
  while [ ! -f "$FAKE_EXEC_RELEASE" ]; do sleep 0.05; done
fi
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

# Reserving the artifact name is atomic: concurrent duplicate dispatches may
# execute exactly once, and the loser must fail before invoking the executor.
mkdir "$tmpdir/dispatch-count"
FAKE_EXEC_COUNT_DIR=$tmpdir/dispatch-count; export FAKE_EXEC_COUNT_DIR
FAKE_EXEC_RELEASE=$tmpdir/dispatch-release; export FAKE_EXEC_RELEASE
run_race() {
  if run_dispatch RACE economy; then printf '0\n'; else printf '1\n'; fi > "$1"
}
run_race "$tmpdir/race-1" & race_1=$!
run_race "$tmpdir/race-2" & race_2=$!
tries=0
while [ "$(find "$tmpdir/dispatch-count" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')" -lt 2 ] \
  && [ "$tries" -lt 40 ]; do
  sleep 0.05
  tries=$((tries + 1))
done
: > "$FAKE_EXEC_RELEASE"
wait "$race_1"; wait "$race_2"
[ "$(cat "$tmpdir"/race-* | grep -c '^0$')" -eq 1 ] || fail 'duplicate concurrent dispatches both succeeded'
[ "$(find "$tmpdir/dispatch-count" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')" -eq 1 ] \
  || fail 'duplicate concurrent dispatches both invoked the executor'
unset FAKE_EXEC_COUNT_DIR FAKE_EXEC_RELEASE

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
grep -q '"reviewer_id": ""' "$(art T1 economy)" || fail 'artifact schema is missing reviewer_id'
grep -q '"adjudicator_id": ""' "$(art T1 economy)" || fail 'artifact schema is missing adjudicator_id'
for judgement in 'accepted=yes' 'blocking=0' 'important=0' 'corrections=0' \
  'reviewer_id=real-child-id' 'adjudicator_id=-'; do
  name=${judgement%%=*}; recorded=${judgement#*=}
  "$harness" record --attempts "$tmpdir/att" --task T1 --arm economy --kind implementation \
    --attempt 1 --field "$name" --value "$recorded" >/dev/null \
    || fail "judgement field $name was rejected"
done
[ "$(field "$(art T1 economy)" accepted)" = yes ] || fail 'recording acceptance did not work'
if "$harness" record --attempts "$tmpdir/att" --task T1 --arm economy --kind implementation \
  --attempt 1 --field invented --value x >/dev/null 2>&1; then fail 'an unknown field was accepted'; fi
before=$(cksum "$(art T1 economy)")
for protected in model effort routing_ok tokens_cached tokens_uncached tokens_output \
  tokens_reasoning cost_usd base_sha prompt_sha256 parent_thread_id child_thread_id; do
  if "$harness" record --attempts "$tmpdir/att" --task T1 --arm economy --kind implementation \
    --attempt 1 --field "$protected" --value forged >/dev/null 2>&1; then
    fail "record changed protected automatic field $protected"
  fi
done
[ "$(cksum "$(art T1 economy)")" = "$before" ] || fail 'a rejected record changed the artifact'

# Recording is serialized. The awk shim snapshots its input before a barrier,
# making a lost update deterministic when both writers can enter together.
run_dispatch RECORD_RACE economy
mkdir "$tmpdir/record-sync" "$tmpdir/bin"
real_awk=$(command -v awk)
cat > "$tmpdir/bin/awk" <<'EOF'
#!/bin/sh
snapshot=$SYNC_DIR/input.$$.json
cp "$6" "$snapshot"
mkdir "$SYNC_DIR/started.$$"
while [ ! -f "$SYNC_DIR/release" ]; do sleep 0.05; done
exec "$REAL_AWK" "$1" "$2" "$3" "$4" "$5" "$snapshot"
EOF
chmod +x "$tmpdir/bin/awk"
record_race() {
  PATH=$tmpdir/bin:$PATH REAL_AWK=$real_awk SYNC_DIR=$tmpdir/record-sync \
    "$harness" record --attempts "$tmpdir/att" --task RECORD_RACE --arm economy \
    --kind implementation --attempt 1 --field "$1" --value "$2" >/dev/null
}
record_race accepted yes & record_1=$!
record_race reviewer_id reviewer-race & record_2=$!
tries=0
while [ "$(find "$tmpdir/record-sync" -name 'started.*' | wc -l | tr -d ' ')" -lt 2 ] \
  && [ "$tries" -lt 40 ]; do
  sleep 0.05
  tries=$((tries + 1))
done
: > "$tmpdir/record-sync/release"
wait "$record_1"; wait "$record_2"
[ "$(field "$(art RECORD_RACE economy)" accepted)" = yes ] || fail 'concurrent record lost accepted'
[ "$(field "$(art RECORD_RACE economy)" reviewer_id)" = reviewer-race ] \
  || fail 'concurrent record lost reviewer_id'

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
unset FAKE_NO_DISPATCH FAKE_ROUTING
out=$("$report" "$tmpdir/att")
if printf '%s' "$out" | awk -F'\t' '$1 == "T1" && NF > 10' | grep -q .; then
  fail 'a row without linked review evidence was counted'
fi
printf '%s' "$out" | grep -q 'T1.*missing-review-artifact' \
  || fail 'a row without linked review evidence lacked a concrete cause'
run_dispatch T1 economy review
out=$("$report" "$tmpdir/att")
printf '%s' "$out" | awk -F'\t' '$1 == "T1" && NF > 10' | grep -q . \
  || fail 'a row with a linked review artifact was dropped'
"$harness" record --attempts "$tmpdir/att" --task T1 --arm economy --kind implementation \
  --attempt 1 --field adjudicator_id --value real-child-id >/dev/null
out=$("$report" "$tmpdir/att")
if printf '%s' "$out" | awk -F'\t' '$1 == "T1" && NF > 10' | grep -q .; then
  fail 'a row without linked adjudication evidence was counted'
fi
printf '%s' "$out" | grep -q 'T1.*missing-adjudication-artifact' \
  || fail 'a row without linked adjudication evidence lacked a concrete cause'
run_dispatch T1 economy adjudication
out=$("$report" "$tmpdir/att")
printf '%s' "$out" | awk -F'\t' '$1 == "T1" && NF > 10' | grep -q . \
  || fail 'a row with linked review and adjudication artifacts was dropped'
"$harness" record --attempts "$tmpdir/att" --task T1 --arm economy --kind implementation \
  --attempt 1 --field adjudicator_id --value - >/dev/null
printf '%s' "$out" | grep -q 'T4.*routing' || fail 'a drifted row was not listed as excluded'
printf '%s' "$out" | grep -q 'T5.*infraestructura' || fail 'a NO-DISPATCH row was not listed as excluded'
printf '%s' "$out" | awk -F'\t' '$1 == "T2" && NF > 10' | grep -q . && fail 'an unjudged row was counted as a result'
printf '%s' "$out" | grep -q 'coste_overhead_usd' || fail 'shared overhead is not reported separately'

# Every judgement is explicit, including "-" when no adjudicator applied. A
# partial judgement or invalid automatic identity/cost is excluded with the
# exact field as its cause, never silently promoted to a complete row.
make_variant() {
  variant=$1; expression=$2
  sed -e "s/\"task\": \"T1\"/\"task\": \"$variant\"/" -e "$expression" \
    "$(art T1 economy)" > "$tmpdir/att/${variant}__economy__implementation__1.json"
}
make_variant MISS_ACCEPTED 's/"accepted": "yes"/"accepted": ""/'
make_variant BAD_ACCEPTED 's/"accepted": "yes"/"accepted": "maybe"/'
make_variant MISS_BLOCKING 's/"blocking": "0"/"blocking": ""/'
make_variant MISS_IMPORTANT 's/"important": "0"/"important": ""/'
make_variant MISS_CORRECTIONS 's/"corrections": "0"/"corrections": ""/'
make_variant MISS_REVIEWER 's/"reviewer_id": "real-child-id"/"reviewer_id": ""/'
make_variant MISS_ADJUDICATOR 's/"adjudicator_id": "-"/"adjudicator_id": ""/'
make_variant BAD_CHILD 's/"child_thread_id": "real-child-id"/"child_thread_id": "-"/'
make_variant BAD_COST 's/"cost_usd":[0-9.]*/"cost_usd":-1/'
out=$("$report" "$tmpdir/att")
for expected in \
  'MISS_ACCEPTED.*missing-accepted' \
  'BAD_ACCEPTED.*invalid-accepted' \
  'MISS_BLOCKING.*missing-blocking' \
  'MISS_IMPORTANT.*missing-important' \
  'MISS_CORRECTIONS.*missing-corrections' \
  'MISS_REVIEWER.*missing-reviewer_id' \
  'MISS_ADJUDICATOR.*missing-adjudicator_id' \
  'BAD_CHILD.*invalid-child_thread_id' \
  'BAD_COST.*invalid-cost_usd'; do
  printf '%s' "$out" | grep -q "$expected" || fail "report did not exclude $expected"
done
rm -f "$tmpdir/att"/MISS_* "$tmpdir/att"/BAD_*

# A cost of one dollar or more must survive parsing. An off-by-one that drops the
# integer part leaves cheap rows looking right and silently divides the expensive
# ones by ten or more — which is the opposite of what a cost comparison needs.
big=$tmpdir/att/BIG__economy__implementation__1.json
sed -e 's/"cost_usd":[0-9.]*/"cost_usd":12.3456/' -e 's/"task": "T1"/"task": "BIG"/' "$(art T1 economy)" > "$big"
sed 's/"task": "T1"/"task": "BIG"/' "$(art T1 economy review)" \
  > "$tmpdir/att/BIG__economy__review__1.json"
"$report" "$tmpdir/att" | grep -q '12.3456' || fail 'a cost above one dollar was truncated by the report'
spent_big=$("$harness" spent --attempts "$tmpdir/att")
awk -v v="$spent_big" 'BEGIN { exit !(v > 12) }' || fail 'a cost above one dollar was truncated by the ledger'
rm -f "$big" "$tmpdir/att/BIG__economy__review__1.json"

# 8. The recorded spend is what enforces the global ceiling, not an estimate.
spent=$("$harness" spent --attempts "$tmpdir/att")
awk -v v="$spent" 'BEGIN { exit !(v > 0) }' || fail 'spend is not accumulated across artifacts'
ceiling=$(awk -v v="$spent" 'BEGIN { printf "%.4f", v + 0.5000 }')
[ "$("$harness" spent --attempts "$tmpdir/att" --ceiling "$ceiling" --reserve 0.5000)" = "$spent" ] \
  || fail 'ceiling gate changed the simple spend output or rejected equality'
too_low=$(awk -v v="$ceiling" 'BEGIN { printf "%.4f", v - 0.0001 }')
if "$harness" spent --attempts "$tmpdir/att" --ceiling "$too_low" --reserve 0.5000 \
  >/dev/null 2>&1; then
  fail 'ceiling gate allowed spent plus reserve above the ceiling'
fi
if "$harness" spent --attempts "$tmpdir/att" --ceiling "$ceiling" >/dev/null 2>&1; then
  fail 'ceiling gate accepted a missing reserve'
fi
if "$harness" spent --attempts "$tmpdir/att" --ceiling 40 --reserve invalid >/dev/null 2>&1; then
  fail 'ceiling gate accepted a non-decimal reserve'
fi

printf '%s\n' 'ok - pilot harness'
