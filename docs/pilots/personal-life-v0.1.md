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
- The host shortened skill descriptions to fit its skill-context budget.
- Eight skills under `~/.agents/skills` had missing frontmatter; one cached
  plugin skill had invalid YAML.
- A GitHub Copilot MCP connection also lacked an access token, but the routing
  result completed without it.

The global activation works in Codex, but the context cost is not acceptable
for trivial classification. Invalid and unused external skills are the first
optimization target; the router itself should not be expanded to compensate.

## Cross-host status

- Claude: global empty-directory smoke passes after login with
  `CLAUDE_GLOBAL_OK | app-direct | no`.
- Gemini: deferred by explicit user decision; CLI `0.46.0` remains unsupported
  for the configured free tier.

## Decision

Pilot status: partial. Keep the global installation active because `doctor`
passes and Codex/Claude behavior is correct. Do not tag `v0.1.0` until the
external-skill errors and measured Codex context cost are addressed. Gemini is
not a release gate for now.

Rollback remains:

```sh
~/agent-scaffolding/scripts/scaffolding uninstall --apply
```
