# Capability Registry

`registry.yaml` is a deliberately small YAML subset. It has one top-level
`capabilities:` key and a sequence of records. Each record uses exactly these
scalar fields:

| Field | Meaning |
| --- | --- |
| `id` | Stable lowercase capability identifier. |
| `owner` | `core` or the actual external/plugin family, never generic `external`. |
| `hosts` | Bracketed list of hosts that can use the capability. |
| `trigger` | Narrow condition that activates it. |
| `mode` | Intended operation, such as `plan`, `implement`, or `review`. |
| `cost` | `fast`, `standard`, or `deep`. |
| `source` | `external:<owner>` when unmanaged; when managed, a repository-relative `/SKILL.md` path or `contract:<path>[#section]` pointing at a contract section. |
| `managed` | `false` for external/plugin entries; `true` only for a local `core` skill. |

The parser intentionally supports only one-line fields, quoted or unquoted
scalars, and simple bracketed host lists. It is not a general YAML parser.
`tests/registry_test.sh` rejects duplicate IDs, missing or malformed fields,
unsafe or missing managed paths, and invalid frontmatter for managed
`SKILL.md` files.

A managed entry may also be a *contract pointer*: `owner: core`, `managed: true`,
and `source: contract:<repository-relative .md path>[#section]`. It carries no
skill file. Orchestration is deliberately one of these: spawning, awaiting, and
correcting a batch of subagents is contract behavior defined in
`agents/README.md`, so the registry points at that section instead of duplicating
it as a separate skill. The validator resolves the path, ignores the fragment,
and rejects absolute or traversing paths.

External and plugin-managed capabilities are inventory entries only. They use
their actual family as `owner`, an exact matching `external:<owner>` source, and
`managed: false`; the installer must never copy or symlink them. A local managed
skill must use `owner: core`, a repository-relative path ending in `/SKILL.md`,
and have `name` and `description` in a closed `---` frontmatter block.

## Trigger precedence

Apply triggers in this order:

1. Explicit user, host, or project instructions.
2. Security or production gates.
3. The narrowest matching capability trigger.
4. No capability is selected when the trigger is not satisfied.

`improve` is only for whole-codebase advisory plans for other agents; a narrow
question or review does not activate it. Use `brainstorming` for unresolved design
choices and `writing-plans` when a substantial specified change benefits from a
plan. An explicit implementation request may already establish the intended
design; these workflows do not require another approval of the same decision.

When names overlap, follow an explicit user choice, then a relevant project
skill, then the maintained personal skill, then the plugin version. Load only
one version of a workflow. Preserve all installed copies until removal or
disabling is explicitly authorized. The host controls discovery; this precedence
does not claim that duplicate metadata has disappeared from the host catalog.

For third-party skills, the global and project contracts govern these boundaries:

- Use the current host's supported skill-loading and agent tools. Do not search
  for a nonexistent `Skill`, `Task`, or `TodoWrite` tool solely to satisfy an example.
- Read relevant references, not whole docs/mockups trees. Reuse the existing task
  record; do not require full implementation code in a plan or a second backlog.
- Continue authorized work across batches and routine fixes. Design questions,
  directory preferences and credential setup do not block independent work.
- Commit, push, PR, merge, deletion and cleanup follow the Git authority already
  granted. Skill examples and successful checks do not grant those permissions.
- Verification follows the project, with evidence bound to the tested state.
  Keep behavioral TDD where required; use appropriate validation for prose,
  generated output and behavior-neutral configuration. Do not cap test counts
  or forbid the existing test framework. Preserve work written before a test;
  establish causal regression coverage without destructive resets.
- Follow canonical routing, package reuse, independent review and retry budgets.
  A skill cannot mandate extra agents, an unavailable Security Guardian, or an
  unlimited review loop. Broad checks are selected by applicability, not a list
  containing every suite, build, benchmark, scan and deployment check.
- Ponytail applies to simplification/dependency decisions or an explicit request;
  it does not persist beyond the task unless requested, reduce acceptance, or
  replace the project's design system and verification requirements.
- Session reports serve explicit handoffs/pauses or substantial unfinished work.
  They do not authorize edits in a read-only review. Complete available authorized
  browser/terminal work before assigning user-only steps.
- Artifact skills require actual work on the artifact, not a filename mention;
  choose one primary format workflow and retain its applicable visual QA.
- Credential decisions gate secret creation/writes and live provider use when
  authority is missing. Offline implementation, planning and mocked tests may
  proceed independently. Never print secrets or bypass a denied destination.

The registry is an allowlist and routing hint, not a replacement for host
installation, local configuration, or runtime policy.
