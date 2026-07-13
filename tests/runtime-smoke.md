# Runtime smoke matrix

## Implemented preconditions

- Canonical source after merge: `~/agent-scaffolding` on `main`.
- Global targets: Codex `AGENTS.md`, Claude `CLAUDE.md`, Gemini `GEMINI.md`.
- Project instructions are optional and must not reference this repository.

## Environments

| Host | Observed version | Global activation | Empty dir | Repo local rules | Nested dir |
|---|---|---|---|---|---|
| Codex CLI | `0.144.1` | pass | pass | no local AGENTS present | pass in `personal-life/src/lifeops_agent` |
| Claude Code | `2.1.205` | pass | pass after login | not run | not run |
| Gemini CLI | `0.46.0` | deferred by user | unsupported free-tier client | not run | not run |

## Required prompts

Each host must return only a compact classification for:

1. A `fast` typo: `app-direct`, no confirmation.
2. A `deep` independent two-domain change: recommend mechanism before action.
3. A task with local read-only restrictions: global policy remains active and
   the local restriction narrows authority.
4. A host without model selection or teams: explicit degradation, no simulated
   Luna/Terra/Sol or workers.

Record command, exit status, mechanism, whether the expected global marker was
loaded, and deviations. Do not retain full transcripts or secrets.

## Observed results

- Global install from canonical `main`: `STATUS managed current`; `DOCTOR ok`.
- Empty-directory Codex: `GLOBAL_OK | app-direct | no`.
- Nested `personal-life` Codex: `FAST | app-direct | no`;
  `STANDARD_MULTI | app-parallel | decisiones, contratos compartidos,
  integracion y verificacion final`; no-teams fallback was explicit.
- Codex reported 17,901 and 27,447 tokens. Both exceed the `fast` intent for
  these classification-only prompts.
- After login, Claude returned `CLAUDE_GLOBAL_OK | app-direct | no`.
- Gemini returned `UNSUPPORTED_CLIENT`; the user explicitly deferred Gemini.

Codex also reported invalid frontmatter in eight externally installed
`~/.agents/skills` entries and one cached plugin skill. These files are not
managed by this repository, but their load errors and skill-description budget
warning are a measured context-cost problem.

## Release gate

Do not tag `v0.1.0` yet. First quarantine/fix the invalid external skills after
identifying their owner and rerun one Codex cost smoke. Gemini is outside the
current release gate by explicit user decision. Do not repeat successful Codex
or Claude behavior cases without new evidence.
