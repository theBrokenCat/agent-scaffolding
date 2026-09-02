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

For each of the four roles, dispatch one throwaway bounded task and record what
the host reports, not what the definition requests:

1. Dispatch the role by name from a session where the global contract is active.
2. Read the host's own report of the subagent's model and reasoning effort —
   session metadata, thread listing, status line, or usage record. Do not ask the
   subagent what model it is; a model's self-report is not evidence.
3. Record the observed pair next to the expected pair.
4. Repeat once for an escalated dispatch, to confirm the escalated alias resolves
   to a different pair and not to the same one.

| Host | Role | Expected model/effort | Observed | Escalated expected | Escalated observed | Verdict |
|---|---|---|---|---|---|---|
| Codex | `explorer` | | | | | |
| Codex | `implementer` | | | | | |
| Codex | `spec-reviewer` | | | | | |
| Codex | `quality-reviewer` | | | | | |
| Claude | `explorer` | | | | | |
| Claude | `implementer` | | | | | |
| Claude | `spec-reviewer` | | | | | |
| Claude | `quality-reviewer` | | | | | |

## Built-in name collisions

`explorer` collides with a host built-in of the same name, and the custom
definition overrides it. That override is deliberate: without it the built-in
runs at the host default instead of the alias this contract assigns.

Verify the override actually took effect, because a silent fall-back to the
built-in looks identical from the outside: confirm the dispatched `explorer`
reports the alias model, and that its returned shape is the role's compact
envelope rather than the built-in's output. Record any other name that collides
with a host built-in when it appears.

## Known degradations

Record these as degradations, never as passes:

- A host that pins the model but exposes no reasoning-effort field materializes
  effort only as an instruction. Effort parity is then unverifiable on that host;
  say so and do not claim the alias held.
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
