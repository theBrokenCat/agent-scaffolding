# Runtime smoke matrix

## Implemented preconditions

- Canonical source after merge: `~/agent-scaffolding` on `main`.
- Global targets: Codex `AGENTS.md`, Claude `CLAUDE.md`, Gemini `GEMINI.md`.
- Project instructions are optional and must not reference this repository.

## Environments

| Host | Observed version | Global activation | Empty dir | Repo local rules | Nested dir |
|---|---|---|---|---|---|
| Codex CLI | `0.144.3` | pass | pass | no local AGENTS present | pass in `personal-life/src/lifeops_agent` |
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

The eight invalid `~/.agents/skills` frontmatters were repaired, the invalid
cached `schedule` skill was removed, GitHub MCP was disabled in favor of `gh`,
and duplicate or unused plugin families were disabled reversibly. A first cost
smoke after syntax repair used 21,450 input tokens (8,960 cached) and still
reported a skill-description budget warning. After plugin pruning, the same
prompt used 21,134 input tokens (8,960 cached) with no skill warning.

The 316-token reduction shows that the remaining input cost is dominated by the
Codex runtime, tools and global instruction context rather than this router.
Further broad capability removal is not justified by the measured return.

## Release gate

Runtime gates pass for the active hosts. Gemini is outside the current release
gate by explicit user decision. The remaining high fixed context cost is a
documented host constraint, not a release blocker for this repository. Merge
and tag remain separate human authorization gates.
