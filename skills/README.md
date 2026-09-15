# Skill selection

The host owns skill discovery, installation and enablement. This document only
explains selection and compatibility; it is not a parallel capability catalog.
Consult the skills actually available in the current host before choosing one.

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


## Consolidated personal workflows

Personal workflows are maintained under `~/.agents/skills`; scaffolding does not
install or delete them.

- `agent-tech-lead`: coordination, delegation briefs and independent batches.
- `agent-code-reviewer`: review requests and independent review; implementers
  cannot approve their own work. Verification follows the project contract.
- `systematic-debugging`: scoped causal diagnosis and affected verification.
- System `skill-creator`: ordinary authoring; personal `skill-evals`: explicitly
  requested evaluations, with host-specific runner limits.
- Native artifact skills: normal file work; `document-file-repair`: narrow
  compatibility/OCR routes with preserved upstream resources.

Do not infer another host's installed catalog from this list. Select one
maintained workflow where duplicates overlap. Plugin enablement belongs to the
host; deleting cache directories is not a substitute for uninstalling a plugin.
