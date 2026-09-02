# Runtime parity matrix

The deterministic tests prove that a definition was generated and installed.
They cannot prove that the host actually ran the subagent on the model and
reasoning effort the alias asked for. That is what this check is for, and it is
the only evidence that lets a run claim its routing held.

**A file on disk is not a pass.** Only an observed model and effort count.

## Preconditions

- A local model map exists and `scripts/gen-agents --map-path` resolves to it,
  not to `settings/schemas/model-map.example.yaml`.
- `scripts/scaffolding status --agents` reports `STATUS agents managed current`.
- The alias table in [`ROUTER.md`](../ROUTER.md) and the role frontmatter in
  [`agents/roles/`](../agents/roles/) are the expected values for this run.

## Procedure per host

Dispatch one throwaway bounded task per materialized state — both the base and
the escalated state of each of the four roles — and record what the host reports,
not what the definition requests. Escalated states are dispatched **by name**
(`<role>-<state>`); a dispatch that passes a model or effort override instead is
not a test of the escalated state, because the definition wins over the override.

1. Dispatch the role by name from a session where the global contract is active.
2. Read the host's own report of the subagent's model and reasoning effort —
   session metadata, thread listing, status line, or usage record. Do not ask the
   subagent what model it is; a model's self-report is not evidence.
3. Record the observed pair next to the expected pair.
4. Repeat once for an escalated dispatch, to confirm the escalated alias resolves
   to a different pair and not to the same one. Observing the base pair again is a
   **not verified**, never a pass: it usually means the escalation never happened.

| Host | Role | Expected model/effort | Observed | Verdict |
|---|---|---|---|---|
| Codex | `explorer` | luna / high | `gpt-5.6-luna` / `high` | pass |
| Codex | `implementer` | luna / xhigh | `gpt-5.6-luna` / `xhigh` | pass |
| Codex | `spec-reviewer` | sol / high | `gpt-5.6-sol` / `high` | pass |
| Codex | `quality-reviewer` | sol / xhigh | `gpt-5.6-sol` / `xhigh` | pass |
| Claude | all four | (see below) | `model_not_found`, HTTP 404 | **fail** |
| Codex | four escalated states | see below | ran at the base pair | **not verified** |

## Run of 2026-09-02

Codex `codex-cli 0.151.0`, Claude Code, against the local model map.

**Codex passes.** Effective values were read from the session rollout
(`~/.codex/sessions/**/rollout-*.jsonl`, fields `payload.model` and
`payload.effort`), not from the installed file and not from the subagent's own
report. The deliberate override of the built-in `explorer` took effect: the
dispatched agent ran on the `economy` pair and returned the role's envelope.

**Claude fails.** All four definitions register in a fresh session, but none
starts:

```text
[claude-code:unrecognized_model] {"model":"gpt-5.6-luna","query_source":"agent:custom:explorer"}
```

A dispatch only completed after passing an explicit model override. See the
portability section below: this is a fail, not the effort degradation that was
predicted.

### Escalated states: not verified

The four base states above are only half the design. Each role also declares an
escalated alias, and those states were dispatched with `spawn_agent`'s explicit
`model` and `reasoning_effort` arguments, `fork_turns: "none"`, arguments
confirmed present in the parent rollout:

| Escalated state | Requested | Observed | Verdict |
| --- | --- | --- | --- |
| `explorer` economy -> balanced | luna / xhigh | luna / high | **not verified** |
| `implementer` balanced -> frontier | sol / xhigh | luna / xhigh | **not verified** |
| `spec-reviewer` high -> xhigh | sol / xhigh | sol / high | **not verified** |
| `quality-reviewer` frontier -> critical | sol / max | sol / xhigh | **not verified** |

Every one ran at its **base** pair. A control with the same overrides and no
`agent_type` applied them correctly, so the rule is the host's: when `agent_type`
names a custom agent, the definition's model and effort win over the spawn
override. The escalation ladder therefore has no working dispatch path today.

Do not read the base rows as covering these. A role verified at `economy` says
nothing about whether it can reach `balanced`.

| Rung | Observed | Verdict |
| --- | --- | --- |
| `critical` pair reachable at all | `gpt-5.6-sol` / `max` | pass, via a spawn with no `agent_type` |
| `diagnostic` rung, manual dispatch | `gpt-5.6-terra` / `high` | pass; Terra is available on the account |

`critical` is reachable but **not** reachable as an escalation of
`quality-reviewer`, which is the only way the contract ever asks for it. The
diagnostic rung is defined as a manual dispatch, so a spawn without `agent_type`
is its legitimate path and that row is a genuine pass.

### Hazard: a forked spawn silently discards the alias

`spawn_agent` with `fork_turns: "all"` makes the subagent inherit the parent
session's model and effort and ignore the agent definition's. Observed twice:

- `explorer` spawned with `fork_turns: "all"` ran at `gpt-5.6-sol` / `xhigh`
  instead of `gpt-5.6-luna` / `high`.
- Control with a pre-existing personal agent declaring `gpt-5.6-luna` / `max`
  also ran at `gpt-5.6-sol` / `xhigh`.

The control matters: the behaviour is the host's, not a defect in the generated
files. There is no error and no warning — the routing is simply gone, and a run
measured that way belongs to a different alias.

This is now a hard rule of the contract, not an observation: see the fork
prohibition in [`AGENTS.md`](../AGENTS.md) and
[`policies/README.md`](../policies/README.md). Spawn without forking turns; when a
fork is genuinely needed, record that the dispatch ran at the parent's pair and
not at the alias.

## Built-in name collisions

`explorer` collides with a host built-in of the same name, and the custom
definition overrides it. That override is deliberate: without it the built-in
runs at the host default instead of the alias this contract assigns.

Verify the override actually took effect, because a silent fall-back to the
built-in looks identical from the outside: confirm the dispatched `explorer`
reports the alias model, and that its returned shape is the role's compact
envelope rather than the built-in's output. Record any other name that collides
with a host built-in when it appears.

## Model ids are not portable across hosts

A model map holds one id per alias, and `gen-agents` writes that id into every
host. That is wrong wherever two hosts do not share a model namespace, and it is
what breaks Claude today: an OpenAI id in a Claude subagent definition is
rejected outright.

Until the map resolves an alias per host, the Claude unit is installed but not
usable, and its rows above are a fail. Do not read the effort degradation below
as covering this: the effort was never reached, because the model was refused
first.

## Known degradations

Record these as degradations, never as passes:

- A host that pins the model but exposes no reasoning-effort field materializes
  effort only as an instruction. Effort parity is then unverifiable on that host;
  say so and do not claim the alias held. Claude Code is such a host: its agent
  frontmatter carries `model` but no reasoning-effort field, so even once the
  model id is portable, effort there stays unverifiable and must be recorded as a
  degradation rather than a pass.
- A host with no subagent definition format at all is out of scope for this
  check. Gemini has no `agents/` unit and `scripts/gen-agents` refuses it rather
  than writing a file the host will ignore.
- If the observed model differs from the expected one, the run is a fail even
  when the task succeeded: the cost and quality numbers of that run belong to a
  different alias.

## Release gate

The agent unit may be declared installed only when every row has an observed
model, every degradation is written down, and no row silently fell back to a host
default.
