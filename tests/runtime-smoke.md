# Runtime smoke matrix

## Implemented preconditions

- Canonical source after merge: `~/agent-scaffolding` on `main`.
- Global targets: Codex `AGENTS.md`, Claude `CLAUDE.md`, Gemini `GEMINI.md`.
- Project instructions are optional and must not reference this repository.

## Environments

| Host | Observed version | Global activation | Empty dir | Repo local rules | Nested dir |
|---|---|---|---|---|---|
| Codex CLI | `0.144.1` | pending merge/install | pending | pending | pending |
| Claude Code | `2.1.205` | pending merge/install | pending | pending | pending |
| Gemini CLI | `0.46.0` | pending merge/install | pending | pending | pending |

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

## Gate

Run this matrix only after the PR is merged and
`~/agent-scaffolding/scripts/scaffolding install --migrate-existing --apply`
has completed. Running it from the feature worktree would validate links that
must later be deleted and is therefore invalid evidence.
