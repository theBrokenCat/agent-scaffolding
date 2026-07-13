# personal-life v0.1 pilot

Date: 2026-07-13
Scaffolding main SHA: `9f779599edaf06f08d7ae222ea50803f21989968`
Project SHA: `4107d0a0e49f975e312d981582b6e23572bf6295`
Mode: read-only routing smoke

## Scope

Validate that the global contract is available without adding an `AGENTS.md`,
`CLAUDE.md` or `GEMINI.md` to `personal-life`. Run from
`src/lifeops_agent` and classify a fast task, an independent multi-scope task,
and a host without teams. Do not edit the project or run its application tests.

## Result

Codex loaded the global flow and returned:

```text
FAST | app-direct | no
STANDARD_MULTI | app-parallel | decisiones, contratos compartidos, integracion y verificacion final
HOST_NO_TEAMS | secuencial con app-delegated; cli-handoff/hybrid si procede
```

The project remained clean. No project-local scaffolding files were created.

## Cost and friction

- Empty-directory classification: 17,901 tokens.
- Nested-project classification: 27,447 tokens.
- Eight local skill frontmatters were repaired and the invalid cached
  `schedule` skill was removed.
- GitHub MCP was disabled in favor of the authenticated `gh` CLI.
- Duplicate and unused plugin families were disabled reversibly.
- The controlled cost smoke moved from 21,450 input tokens (8,960 cached) with
  a skill-budget warning to 21,134 (8,960 cached) without the warning.

The global activation works in Codex. Plugin pruning removed the skill-budget
warning but reduced input by only 316 tokens, so the remaining cost is dominated
by Codex runtime, tool and global instruction context. The router should not be
expanded, and further broad capability removal is not justified by this result.

## Cross-host status

- Claude: global empty-directory smoke passes after login with
  `CLAUDE_GLOBAL_OK | app-direct | no`.
- Gemini: deferred by explicit user decision; CLI `0.46.0` remains unsupported
  for the configured free tier.

## Decision

Pilot status: pass for active hosts. Keep the global installation active because
`doctor` passes, Codex/Claude behavior is correct, invalid skill errors are gone,
and the residual context cost has been isolated as a host-level constraint.
Gemini is not a release gate for now.

Rollback remains:

```sh
~/agent-scaffolding/scripts/scaffolding uninstall --apply
```
