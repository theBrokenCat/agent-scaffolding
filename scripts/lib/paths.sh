#!/bin/sh

scaffolding_init_paths() {
  scaffolding_script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
  SCAFFOLDING_ROOT=$(CDPATH= cd -- "$scaffolding_script_dir/.." && pwd -P)

  case ${SCAFFOLDING_HOME_INPUT-} in
    ''|/|.|..|*'\n'*|*'\r'*|*'|'*)
      printf '%s\n' 'STOP unsafe HOME' >&2
      return 1
      ;;
    /*) ;;
    *)
      printf '%s\n' 'STOP HOME must be an existing absolute directory' >&2
      return 1
      ;;
  esac

  if [ ! -d "$SCAFFOLDING_HOME_INPUT" ]; then
    printf '%s\n' 'STOP HOME must be an existing absolute directory' >&2
    return 1
  fi

  SCAFFOLDING_HOME=$(CDPATH= cd -- "$SCAFFOLDING_HOME_INPUT" && pwd -P)
  if [ "$SCAFFOLDING_HOME" = / ]; then
    printf '%s\n' 'STOP unsafe HOME' >&2
    return 1
  fi

  SCAFFOLDING_STATE_DIR=$SCAFFOLDING_HOME/.local/state/agent-scaffolding
  SCAFFOLDING_MANIFEST=$SCAFFOLDING_STATE_DIR/manifest
  SCAFFOLDING_BACKUP_DIR=$SCAFFOLDING_STATE_DIR/backups
}

scaffolding_targets() {
  printf '%s|%s|%s\n' \
    codex "$SCAFFOLDING_HOME/.codex/AGENTS.md" "$SCAFFOLDING_ROOT/AGENTS.md" \
    claude "$SCAFFOLDING_HOME/.claude/CLAUDE.md" "$SCAFFOLDING_ROOT/CLAUDE.md" \
    gemini "$SCAFFOLDING_HOME/.gemini/GEMINI.md" "$SCAFFOLDING_ROOT/GEMINI.md"
}

scaffolding_target_parents_are_safe() {
  scaffolding_targets | while IFS='|' read -r name destination source; do
    destination_dir=$(dirname "$destination")
    [ ! -L "$destination_dir" ] || {
      printf '%s\n' "STOP destination parent is a symlink: $destination_dir" >&2
      exit 1
    }
  done
}

scaffolding_state_path_is_safe() {
  for state_path in \
    "$SCAFFOLDING_HOME/.local" \
    "$SCAFFOLDING_HOME/.local/state" \
    "$SCAFFOLDING_STATE_DIR" \
    "$SCAFFOLDING_BACKUP_DIR" \
    "$SCAFFOLDING_MANIFEST"; do
    [ ! -L "$state_path" ] || {
      printf '%s\n' "STOP state path is a symlink: $state_path" >&2
      return 1
    }
  done
}
