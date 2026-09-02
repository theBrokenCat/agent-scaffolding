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
| Claude | model per state | mapped id | the state's mapped model | pass |
| Claude | effort per state | — | no field on this host | **degradation** |
| Codex | nine materialized states | see below | every state on its own pair | pass |

## Run of 2026-09-02

Codex `codex-cli 0.151.0`, Claude Code, against the local model map.

**Codex passes.** Effective values were read from the session rollout
(`~/.codex/sessions/**/rollout-*.jsonl`, fields `payload.model` and
`payload.effort`), not from the installed file and not from the subagent's own
report. The deliberate override of the built-in `explorer` took effect: the
dispatched agent ran on the `economy` pair and returned the role's envelope.

**Claude passes on model, degrades on effort.** The earlier failure
(`[claude-code:unrecognized_model] {"model":"gpt-5.6-luna", ...}`, HTTP 404) came
from one shared model id per alias; with the map resolving per host it is gone.

Model routing was verified from a session whose own model differs from the
state's, so the subagent's model is separable in the usage record:

- Parent session on `claude-opus-5`; dispatched `explorer-economy` (mapped to
  `claude-sonnet-5`). The run reports two models, `claude-opus-5` for the parent
  and **`claude-sonnet-5`** for the subagent. The definition decided the model.
- `quality-reviewer-critical` (mapped to `claude-opus-5`) dispatched without
  overrides and completed with no model error.

Effort is **not** verified and cannot be: see the degradations.

### All nine states verified

After materializing one file per (role, state), every state was dispatched by
name with `fork_turns: "none"` and **no** model or effort override — the routing
comes from the definition, which is the only thing the host honours.

| State | Expected | Observed | Verdict |
| --- | --- | --- | --- |
| `explorer` (bare, overrides the built-in) | luna / high | `gpt-5.6-luna` / `high` | pass |
| `explorer-economy` | luna / high | `gpt-5.6-luna` / `high` | pass |
| `explorer-balanced` | luna / xhigh | `gpt-5.6-luna` / `xhigh` | pass |
| `implementer-balanced` | luna / xhigh | `gpt-5.6-luna` / `xhigh` | pass |
| `implementer-frontier` | sol / xhigh | `gpt-5.6-sol` / `xhigh` | pass |
| `spec-reviewer-frontier-high` | sol / high | `gpt-5.6-sol` / `high` | pass |
| `spec-reviewer-frontier-xhigh` | sol / xhigh | `gpt-5.6-sol` / `xhigh` | pass |
| `quality-reviewer-frontier` | sol / xhigh | `gpt-5.6-sol` / `xhigh` | pass |
| `quality-reviewer-critical` | sol / max | `gpt-5.6-sol` / `max` | pass |

`quality-reviewer-critical` is the row that matters most: `max` is the pair the
contract only ever asks for by escalation, and until the states were separate
files there was no way to reach it. Each base state also reported the correct
escalated name to dispatch, so the ladder is navigable from inside the definition.

### Superseded: escalation by override

Before the states were separate files, the four escalated states were dispatched
by passing `model` and `reasoning_effort` to `spawn_agent` with `agent_type` set.
All four ran at their **base** pair; a control with the same overrides and no
`agent_type` applied them correctly. That is the host rule the contract now
encodes as a hard prohibition: the definition wins over the override, so
escalation is dispatched by name.

Kept here because it is the failure a future run will re-create by habit: an
escalation that silently returns the base pair looks like a working dispatch.

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

Fixed. The map now resolves an alias per host (`model_codex`, `model_claude`),
and a host with no id for an alias stops the generator instead of borrowing
another host's. The earlier failure — an OpenAI id rejected outright by Claude —
came from one shared id per alias.

The Claude mapping mirrors the Codex curves: `economy` and `balanced` land on the
same model, `frontier` and `critical` on another. See the degradations below for
what that costs.

## Known degradations

Record these as degradations, never as passes:

- **Effort is an instruction, not a field, on Claude.** Its agent frontmatter
  carries `model` and no reasoning-effort field, so the effort half of every
  alias travels as prose in the definition and cannot be observed. Half of each
  Claude row is therefore unverifiable by construction. Record it; never call it
  parity.
- **`critical` is not a real rung on Claude.** With no effort field, `frontier`
  and `critical` resolve to the same model (`claude-opus-5`), and so do `economy`
  and `balanced` (`claude-sonnet-5`). Four aliases collapse to two effective
  settings. An escalation that changes nothing observable is not an escalation:
  on Claude, treat `quality-reviewer-critical` as `frontier` with a stricter
  brief, not as a stronger run.
- **Fable 5.1 is positioned above Opus but is unusable on this account.** The
  model picker cache in this installation describes it as "Most capable for your
  hardest and longest-running tasks" — which is exactly the long-horizon gate —
  but a dispatch returns `You've hit your monthly spend limit`, not an unknown
  model. So the ceiling is a billing limit, not a capability one. `frontier` and
  `critical` stay on `claude-opus-5`; revisit if that limit is lifted.
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
