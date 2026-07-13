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
| `source` | `external:<owner>` when unmanaged, or a repository-relative `/SKILL.md` path when managed. |
| `managed` | `false` for external/plugin entries; `true` only for a local `core` skill. |

The parser intentionally supports only one-line fields, quoted or unquoted
scalars, and simple bracketed host lists. It is not a general YAML parser.
`tests/registry_test.sh` rejects duplicate IDs, missing or malformed fields,
unsafe or missing managed paths, and invalid frontmatter for managed
`SKILL.md` files.

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

`improve` is exclusively a read-only, whole-codebase advisory plan for other
agents and never implements. `brainstorming` establishes intent and design;
`writing-plans` is selected only after that design is approved and produces the
implementation plan. Therefore a general request to analyze or advise selects
`improve`, while an approved design selects `writing-plans`.

The registry is an allowlist and routing hint, not a replacement for host
installation, local configuration, or runtime policy.
