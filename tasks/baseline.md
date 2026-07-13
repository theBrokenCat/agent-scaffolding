# Global activation baseline

Captured: 2026-07-13
Repository: `theBrokenCat/agent-scaffolding`
Branch: `feat/v0.1`
Planning SHA: `1c7ab05aa04e804a70faeb180abb8555832487fe`

## Accepted deferral

The user explicitly deferred rotation of the Outline credentials exposed in an
earlier local command output. No credential value is stored here. This remains
an open security risk and does not authorize printing, copying or committing
the current or replacement value.

## Global instructions

| Destination | State | Evidence | Migration strategy |
|---|---|---|---|
| `~/.codex/AGENTS.md` | regular file | SHA-256 `d7490f3e33d171daa2100e381b165999bb3d7d1e53efe219348b4b724a039bcc` | backup, preserve applicable rules centrally, then managed link |
| `~/.claude/CLAUDE.md` | missing | path inventory | create managed link |
| `~/.gemini/GEMINI.md` | symlink to `~/z_dev/GEMINI.md` | link target inventory | backup link metadata, replace only through explicit apply, restore on uninstall |

## Capability directories

| Path | State | Top-level directories | Ownership |
|---|---|---:|---|
| `~/.codex/skills` | present | 4 | mixed local/plugin; never replace directory |
| `~/.claude/skills` | present | 24 | mixed local/plugin; never replace directory |
| `~/.gemini/skills` | missing | 0 | leave absent unless a managed capability requires it |
| `~/.claude/agents` | missing | 0 | create only for individually managed roles |
| `~/.gemini/agents` | missing | 0 | host capability must be proven before use |

Counts are inventory signals, not a complete capability count: Codex can expose
skills from plugin and shared roots outside `~/.codex/skills`.

## Settings policy

Settings files were not read for this baseline. Full settings, MCP environment,
credentials, trust state, machine paths and UI preferences remain local. The
scaffolding may version schemas and recommendations, but it must not replace or
symlink complete settings files.

## Recovery requirements

- Store manifests and backups outside the repository under the user's home.
- Record destination type, checksum or link target before mutation.
- Refuse unknown conflicts unless the apply operation explicitly supports and
  records their backup.
- Restore the exact previous file, missing state or symlink on uninstall.
- Never include secret values in status, doctor, logs, commits or pull requests.
