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
printf '{"payload":{"model":"%s","effort":"%s"}}\n' "$model" "$effort" \
  > "$PILOT_SESSIONS_DIR/rollout-fixture-thread-1.jsonl"
EOF
chmod +x "$tmpdir/fake-exec"
PILOT_EXEC=$tmpdir/fake-exec
export PILOT_EXEC

# The header is the row contract; judgment columns must exist and stay empty.
header=$("$harness" --header)
for column in tarea brazo routing_ok tokens_no_cacheados tokens_reasoning coste_hasta_aceptado blocking_escapados; do
  printf '%s' "$header" | tr '\t' '\n' | grep -qx "$column" || fail "header is missing column $column"
done

row=$("$harness" --task T1 --block mecanicas --arm economy --prompt "$tmpdir/prompt.txt" --order 2 --results "$tmpdir/out.tsv")
value() { printf '%s' "$row" | cut -f "$1"; }
[ "$(value 1)" = T1 ] || fail 'task not recorded'
[ "$(value 3)" = economy ] || fail 'arm not recorded'
[ "$(value 4)" = 2 ] || fail 'order not recorded'
[ "$(value 5)" = fixture-economy ] || fail 'expected model not resolved from the map'
[ "$(value 7)" = fixture-economy ] || fail 'observed model not read from the rollout'
[ "$(value 9)" = yes ] || fail 'routing_ok should pass when observed matches the arm'
[ "$(value 10)" = 400 ] || fail 'cached tokens not recorded'
[ "$(value 11)" = 600 ] || fail 'uncached tokens must be input minus cached'
[ "$(value 13)" = 25 ] || fail 'reasoning tokens not recorded'
[ "$(value 15)" = 1 ] || fail 'tool failures not counted'

# Judgment columns are never invented by the harness.
for column in 16 17 18 19 20 21 22 23 24 25; do
  [ -z "$(value "$column")" ] || fail "harness filled judgment column $column"
done

# The results file accumulates rows under one header.
[ "$(head -1 "$tmpdir/out.tsv")" = "$header" ] || fail 'results file lacks the header'
"$harness" --task T2 --block mecanicas --arm balanced --prompt "$tmpdir/prompt.txt" --results "$tmpdir/out.tsv" >/dev/null
[ "$(wc -l < "$tmpdir/out.tsv")" -eq 3 ] || fail 'results file did not accumulate rows'

# A run that drifted off its arm is marked, not silently averaged in.
drift=$(FAKE_ROUTING=drift "$harness" --task T3 --block mecanicas --arm frontier --prompt "$tmpdir/prompt.txt" 2>"$tmpdir/warn.txt")
[ "$(printf '%s' "$drift" | cut -f 9)" = NO ] || fail 'routing drift not marked'
grep -q 'belongs to another arm' "$tmpdir/warn.txt" || fail 'routing drift not warned about'

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
