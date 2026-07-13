---
name: registry-validation
description: Validate the local capability registry and managed skill contracts.
---

# Registry Validation

Use this capability when `skills/registry.yaml` or a managed `SKILL.md` changes.
Run `sh tests/registry_test.sh` from the repository root and report the exact
failure before suggesting a correction. Keep external/plugin-managed entries
as inventory only; do not copy, symlink, or rewrite their content.
