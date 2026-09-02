#!/bin/sh

set -eu

root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
harness=$root/scripts/pilot-run
tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/pilot-run-test.XXXXXX")
trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

fail() { printf '%s\n' "FAIL: $*" >&2; exit 1; }

mkdir -p "$tmpdir/cfg/agent-scaffolding" "$tmpdir/sessions"
cat > "$tmpdir/cfg/agent-scaffolding/model-map.yaml" <<'EOF'
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
EOF
XDG_CONFIG_HOME=$tmpdir/cfg
export XDG_CONFIG_HOME
PILOT_SESSIONS_DIR=$tmpdir/sessions
export PILOT_SESSIONS_DIR

printf 'haz algo acotado\n' > "$tmpdir/prompt.txt"

# A fake exec keeps the harness testable without spending credits. It writes the
# event stream the harness parses and the rollout it reads routing from.
cat > "$tmpdir/fake-exec" <<'EOF'
#!/bin/sh
model=$1
effort=$2
[ "${FAKE_ROUTING-}" = drift ] && { model=other-model; effort=low; }
cat <<JSON
{"type":"thread.started","thread_id":"fixture-thread-1"}
{"type":"item.completed","item":{"type":"error","message":"tool blew up"}}
{"type":"turn.completed","usage":{"input_tokens":1000,"cached_input_tokens":400,"output_tokens":50,"reasoning_output_tokens":25}}
JSON
mkdir -p "$PILOT_SESSIONS_DIR/2026/09/02"
rm -f "$PILOT_SESSIONS_DIR/2026/09/02/rollout-child.jsonl"
# The parent always runs at the host default. Measuring it would mark every row
# off-arm, so the fixture makes parent and child differ on purpose.
# The id in `thread.started` is NOT always the id the child records as its
# parent, so the fixture makes them differ and joins through the rollout's cwd.
printf '{"payload":{"model":"host-default","effort":"xhigh","id":"rollout-id-1","cwd":"%s"}}\n' \
  "$FAKE_CWD" > "$PILOT_SESSIONS_DIR/2026/09/02/rollout-parent.jsonl"
if [ "${FAKE_NO_DISPATCH-}" != yes ]; then
  # The child carries the real cost. The parent's numbers below are deliberately
  # different and much smaller: measuring them understates the arm.
  printf '{"payload":{"thread_source":"subagent","parent_thread_id":"rollout-id-1","model":"%s","effort":"%s"}}\n' \
    "$model" "$effort" > "$PILOT_SESSIONS_DIR/2026/09/02/rollout-child.jsonl"
  printf '{"payload":{"info":{"total_token_usage":{"input_tokens":9000,"cached_input_tokens":6000,"output_tokens":700,"reasoning_output_tokens":300}}}}\n' \
    >> "$PILOT_SESSIONS_DIR/2026/09/02/rollout-child.jsonl"
fi
EOF
chmod +x "$tmpdir/fake-exec"
PILOT_EXEC=$tmpdir/fake-exec
export PILOT_EXEC
FAKE_CWD=$tmpdir/run
mkdir -p "$FAKE_CWD"
export FAKE_CWD

# The header is the row contract; judgment columns must exist and stay empty.
header=$("$harness" --header)
for column in tarea brazo routing_ok tokens_no_cacheados tokens_reasoning coste_hasta_aceptado blocking_escapados; do
  printf '%s' "$header" | tr '\t' '\n' | grep -qx "$column" || fail "header is missing column $column"
done

row=$("$harness" --task T1 --block mecanicas --arm economy --prompt "$tmpdir/prompt.txt" --order 2 --cwd "$FAKE_CWD" --results "$tmpdir/out.tsv")
value() { printf '%s' "$row" | cut -f "$1"; }
[ "$(value 1)" = T1 ] || fail 'task not recorded'
[ "$(value 3)" = economy ] || fail 'arm not recorded'
[ "$(value 4)" = 2 ] || fail 'order not recorded'
[ "$(value 5)" = fixture-economy ] || fail 'expected model not resolved from the map'
[ "$(value 7)" = fixture-economy ] || fail 'observed model not read from the subagent rollout'
if [ "$(value 7)" = host-default ]; then fail 'the harness measured the parent thread, not the subagent'; fi
# The join must survive the event id and the rollout id being different.
grep -Fq '"id":"rollout-id-1"' "$PILOT_SESSIONS_DIR/2026/09/02/rollout-parent.jsonl" \
  || fail 'the fixture no longer exercises the id mismatch'
[ "$(value 9)" = yes ] || fail 'routing_ok should pass when observed matches the arm'
# Cost is the subagent's, not the parent's. The parent reports 400/600/50/25;
# reading it would understate the arm by an order of magnitude.
[ "$(value 10)" = 6000 ] || fail 'cached tokens were not read from the subagent'
[ "$(value 11)" = 3000 ] || fail 'uncached tokens must be the subagent input minus cached'
[ "$(value 12)" = 700 ] || fail 'output tokens were not read from the subagent'
[ "$(value 13)" = 300 ] || fail 'reasoning tokens were not read from the subagent'
if [ "$(value 10)" = 400 ]; then fail 'the harness measured the parent cost, not the arm'; fi
[ "$(value 15)" = 1 ] || fail 'tool failures not counted'

# Judgment columns are never invented by the harness.
for column in 16 17 18 19 20 21 22 23 24 25; do
  [ -z "$(value "$column")" ] || fail "harness filled judgment column $column"
done

# The results file accumulates rows under one header.
[ "$(head -1 "$tmpdir/out.tsv")" = "$header" ] || fail 'results file lacks the header'
"$harness" --task T2 --block mecanicas --arm balanced --prompt "$tmpdir/prompt.txt" --cwd "$FAKE_CWD" --results "$tmpdir/out.tsv" >/dev/null
[ "$(wc -l < "$tmpdir/out.tsv")" -eq 3 ] || fail 'results file did not accumulate rows'

# A run that drifted off its arm is marked, not silently averaged in.
drift=$(FAKE_ROUTING=drift "$harness" --task T3 --block mecanicas --arm frontier --prompt "$tmpdir/prompt.txt" --cwd "$FAKE_CWD" 2>"$tmpdir/warn.txt")
[ "$(printf '%s' "$drift" | cut -f 9)" = NO ] || fail 'routing drift not marked'
grep -q 'belongs to another arm' "$tmpdir/warn.txt" || fail 'routing drift not warned about'

# The hard cap kills a dispatch that overruns and marks the row instead of
# letting it spend. codex exec has no cap of its own.
cat > "$tmpdir/slow-exec" <<'EOF'
#!/bin/sh
sleep 120
EOF
chmod +x "$tmpdir/slow-exec"
capped=$(PILOT_EXEC=$tmpdir/slow-exec "$harness" --task T9 --block mecanicas --arm economy \
  --prompt "$tmpdir/prompt.txt" --max-seconds 5 2>"$tmpdir/cap.txt")
[ "$(printf '%s' "$capped" | cut -f 9)" = KILLED ] || fail 'an overrunning dispatch was not marked KILLED'
grep -q 'hard cap' "$tmpdir/cap.txt" || fail 'the hard cap did not warn'
[ "$(printf '%s' "$capped" | cut -f 14)" -lt 60 ] || fail 'the dispatch was not actually killed'
if "$harness" --task TA --block mecanicas --arm economy --prompt "$tmpdir/prompt.txt" --max-seconds 0 >/dev/null 2>&1; then
  fail 'a zero budget was accepted'
fi

# A dispatch that never spawned a subagent is a failed dispatch, not a row
# measured at the parent's pair.
nodisp=$(FAKE_NO_DISPATCH=yes "$harness" --task T8 --block mecanicas --arm economy \
  --prompt "$tmpdir/prompt.txt" --cwd "$FAKE_CWD" 2>"$tmpdir/nodisp.txt")
[ "$(printf '%s' "$nodisp" | cut -f 9)" = NO-DISPATCH ] || fail 'a missing subagent was not reported'
grep -q 'never dispatched a subagent' "$tmpdir/nodisp.txt" || fail 'no warning for a missing dispatch'

# Arm order is randomised per task and covers every arm exactly once.
printf 'T1\tmecanicas\teconomy,balanced\nT2\tlargo\teconomy,balanced,frontier\n' > "$tmpdir/tasks.tsv"
order=$("$harness" --order --tasks "$tmpdir/tasks.tsv" --seed 7)
[ "$(printf '%s\n' "$order" | wc -l)" -eq 5 ] || fail 'order did not emit one row per task-arm'
[ "$(printf '%s\n' "$order" | awk -F'\t' '$1=="T2"' | cut -f3 | sort | tr '\n' ' ')" = 'balanced economy frontier ' ] \
  || fail 'order dropped or duplicated an arm'
[ "$(printf '%s\n' "$order" | awk -F'\t' '$1=="T2"' | cut -f4 | sort | tr '\n' ' ')" = '1 2 3 ' ] \
  || fail 'order positions are not 1..n'
same=$("$harness" --order --tasks "$tmpdir/tasks.tsv" --seed 7)
[ "$order" = "$same" ] || fail 'a seeded order is not reproducible'

# Unknown arms and missing inputs stop instead of producing a row.
if "$harness" --task T4 --block mecanicas --arm nonexistent --prompt "$tmpdir/prompt.txt" >/dev/null 2>&1; then
  fail 'unknown arm accepted'
fi
if "$harness" --task T5 --block mecanicas --arm economy --prompt "$tmpdir/absent.txt" >/dev/null 2>&1; then
  fail 'missing prompt accepted'
fi

printf '%s\n' 'ok - pilot harness'
