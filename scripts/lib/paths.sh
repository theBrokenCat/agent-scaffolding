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

  case ${SCAFFOLDING_TARGET_SET:-instructions} in
    instructions)
      SCAFFOLDING_MANIFEST=$SCAFFOLDING_STATE_DIR/manifest
      SCAFFOLDING_BACKUP_NAME=backups
      ;;
    agents-codex|agents-claude)
      scaffolding_agent_host=${SCAFFOLDING_TARGET_SET#agents-}
      SCAFFOLDING_MANIFEST=$SCAFFOLDING_STATE_DIR/manifest.agents.$scaffolding_agent_host
      SCAFFOLDING_BACKUP_NAME=backups.agents.$scaffolding_agent_host
      ;;
    *)
      printf '%s\n' 'STOP unknown target set' >&2
      return 1
      ;;
  esac
  SCAFFOLDING_BACKUP_DIR=$SCAFFOLDING_STATE_DIR/$SCAFFOLDING_BACKUP_NAME
}

# The instruction unit and the per-host agent unit are installed, verified and
# reverted separately: they have different destinations, different lifecycles and
# their own manifest. `scaffolding_targets` is the single seam between them.
scaffolding_targets() {
  case ${SCAFFOLDING_TARGET_SET:-instructions} in
    agents-*) scaffolding_agent_targets "${SCAFFOLDING_TARGET_SET#agents-}" ;;
    *) scaffolding_instruction_targets ;;
  esac
}

# One host per unit. A host whose definitions are unusable must be revertible
# without taking down a host whose definitions work.
scaffolding_agent_targets() {
  scaffolding_host=$1
  "$SCAFFOLDING_ROOT/scripts/gen-agents" --host "$scaffolding_host" --list |
    while IFS='|' read -r role_name file_name role_file; do
      [ -n "$role_name" ] || continue
      printf '%s|%s|%s\n' \
        "$scaffolding_host-$role_name" \
        "$SCAFFOLDING_HOME/.$scaffolding_host/agents/$file_name" \
        "$role_file"
    done
}

# Renders one host definition from its canonical role. A missing local model map
# stops here rather than installing the example's code names into a host.
scaffolding_render_agent() {
  scaffolding_render_destination=$1
  case $scaffolding_render_destination in
    */.codex/agents/*) scaffolding_render_host=codex ;;
    */.claude/agents/*) scaffolding_render_host=claude ;;
    *) return 1 ;;
  esac
  scaffolding_render_role=${scaffolding_render_destination##*/}
  scaffolding_render_role=${scaffolding_render_role%.*}
  "$SCAFFOLDING_ROOT/scripts/gen-agents" \
    --host "$scaffolding_render_host" \
    --role "$scaffolding_render_role" \
    --require-local-map
}

scaffolding_instruction_targets() {
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
