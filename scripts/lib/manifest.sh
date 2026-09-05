#!/bin/sh

# Repository-local Git variables (for example from hooks) must not override
# the path whose identity/SHA we are inspecting. Keep the caller environment.
scaffolding_git_at() (
  scaffolding_git_environment=$(git rev-parse --local-env-vars) || exit 1
  for scaffolding_git_variable in $scaffolding_git_environment; do
    unset "$scaffolding_git_variable"
  done
  git -C "$@"
)

scaffolding_source_sha() {
  scaffolding_git_at "$SCAFFOLDING_ROOT" rev-parse HEAD 2>/dev/null || printf '%s\n' unknown
}

scaffolding_git_common_dir() (
  scaffolding_git_root=$1
  scaffolding_top=$(scaffolding_git_at "$scaffolding_git_root" rev-parse --show-toplevel 2>/dev/null) || return 1
  scaffolding_top=$(CDPATH= cd -- "$scaffolding_top" && pwd -P) || return 1
  [ "$scaffolding_top" = "$scaffolding_git_root" ] || return 1
  # The line-based manifest cannot represent LF in a root. Reject it before
  # passing a pattern to grep, where LF would separate multiple patterns.
  case $scaffolding_git_root in *'
'*) return 1 ;; esac
  scaffolding_registry=$(mktemp "${TMPDIR:-/tmp}/scaffolding-worktrees.XXXXXX") || return 1
  trap 'rm -f "$scaffolding_registry"' EXIT HUP INT TERM
  scaffolding_git_at "$scaffolding_git_root" worktree list --porcelain -z > "$scaffolding_registry" || return 1
  grep -zFx "worktree $scaffolding_git_root" "$scaffolding_registry" >/dev/null || return 1
  scaffolding_common_dir=$(scaffolding_git_at "$scaffolding_git_root" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || return 1
  [ -d "$scaffolding_common_dir" ] || return 1
  (CDPATH= cd -- "$scaffolding_common_dir" && pwd -P)
)

# Read-only checks may use the installed checkout only after proving that the
# caller and recorded root share the same resolved Git common directory.
scaffolding_use_manifest_source_for_read_only() {
  SCAFFOLDING_CALLER_ROOT=
  scaffolding_state_path_is_safe || return 1
  [ -f "$SCAFFOLDING_MANIFEST" ] || return 1
  [ "$(grep -c '^source_root=' "$SCAFFOLDING_MANIFEST")" -eq 1 ] || return 1
  scaffolding_manifest_root=$(sed -n 's/^source_root=//p' "$SCAFFOLDING_MANIFEST")
  case $scaffolding_manifest_root in
    ''|/|.|..|*'\n'*|*'\r'*|*'|'*) return 1 ;;
    /*) ;;
    *) return 1 ;;
  esac
  [ -d "$scaffolding_manifest_root" ] || return 1
  scaffolding_manifest_root=$(CDPATH= cd -- "$scaffolding_manifest_root" && pwd -P) || return 1
  scaffolding_manifest_static_is_valid "$scaffolding_manifest_root" || return 1
  scaffolding_caller_common=$(scaffolding_git_common_dir "$SCAFFOLDING_ROOT") || return 1
  scaffolding_manifest_common=$(scaffolding_git_common_dir "$scaffolding_manifest_root") || return 1
  [ "$scaffolding_caller_common" = "$scaffolding_manifest_common" ] || return 1
  if [ "$scaffolding_manifest_root" != "$SCAFFOLDING_ROOT" ]; then
    SCAFFOLDING_CALLER_ROOT=$SCAFFOLDING_ROOT
    SCAFFOLDING_ROOT=$scaffolding_manifest_root
  fi
}

# The instruction unit records symlinks (6 fields, version 2). The agent unit
# records generated files and their checksum (7 fields, version 1), so drift in a
# rendered definition is detectable without re-reading the host.
scaffolding_is_agent_unit() {
  case ${SCAFFOLDING_TARGET_SET:-instructions} in
    agents-*) return 0 ;;
    *) return 1 ;;
  esac
}

scaffolding_manifest_version() {
  case ${SCAFFOLDING_TARGET_SET:-instructions} in
    agents-*) printf '%s\n' 1 ;;
    *) printf '%s\n' 2 ;;
  esac
}

scaffolding_manifest_exists() {
  [ -e "$SCAFFOLDING_MANIFEST" ] || [ -L "$SCAFFOLDING_MANIFEST" ]
}

# This phase reads only manifest text. It must run before scaffolding_targets,
# whose agent branch invokes the selected checkout's generator.
scaffolding_manifest_static_is_valid() (
  scaffolding_expected_root=$1
  scaffolding_state_path_is_safe || return 1
  [ -f "$SCAFFOLDING_MANIFEST" ] || return 1
  grep -Fqx "version=$(scaffolding_manifest_version)" "$SCAFFOLDING_MANIFEST" || return 1
  [ "$(grep -c '^source_root=' "$SCAFFOLDING_MANIFEST")" -eq 1 ] || return 1
  grep -Fqx "source_root=$scaffolding_expected_root" "$SCAFFOLDING_MANIFEST" || return 1
  grep -Eq '^source_sha=[0-9a-f]{40}$|^source_sha=unknown$' "$SCAFFOLDING_MANIFEST" || return 1
  grep -Eq '^created_at=[0-9]{4}-[0-9]{2}-[0-9]{2}T' "$SCAFFOLDING_MANIFEST" || return 1
  scaffolding_entry_count=0
  while IFS='|' read -r kind name destination previous reference source remaining; do
    [ "$kind" = entry ] || continue
    scaffolding_entry_count=$((scaffolding_entry_count + 1))
    if scaffolding_is_agent_unit; then
      role_file=${source#"$scaffolding_expected_root/agents/roles/"}
      [ "$role_file" != "$source" ] || return 1
      case $role_file in *.md) ;; *) return 1 ;; esac
      role_stem=${role_file%.md}
      case $role_stem in ''|*[!a-z0-9-]*) return 1 ;; esac
    else
      case $name in
        codex) expected_source=$scaffolding_expected_root/AGENTS.md ;;
        claude) expected_source=$scaffolding_expected_root/CLAUDE.md ;;
        gemini) expected_source=$scaffolding_expected_root/GEMINI.md ;;
        *) return 1 ;;
      esac
      [ "$source" = "$expected_source" ] || return 1
    fi
  done < "$SCAFFOLDING_MANIFEST"
  [ "$scaffolding_entry_count" -gt 0 ]
)

scaffolding_manifest_is_valid() {
  scaffolding_manifest_static_is_valid "$SCAFFOLDING_ROOT" || return 1

  scaffolding_targets | while IFS='|' read -r name destination source; do
    line=$(grep -F "entry|$name|$destination|" "$SCAFFOLDING_MANIFEST" || :)
    [ "$(printf '%s\n' "$line" | grep -c .)" -eq 1 ] || exit 1
    old_ifs=$IFS
    IFS='|'
    set -- $line
    IFS=$old_ifs
    [ "$1" = entry ] && [ "$2" = "$name" ] && [ "$3" = "$destination" ] || exit 1
    case $4 in
      absent) [ "$5" = - ] || exit 1 ;;
      file) [ "$5" = "$SCAFFOLDING_BACKUP_NAME/$name.file" ] && [ -f "$SCAFFOLDING_STATE_DIR/$5" ] || exit 1 ;;
      symlink) [ "$5" = "$SCAFFOLDING_BACKUP_NAME/$name.link" ] && [ -f "$SCAFFOLDING_STATE_DIR/$5" ] || exit 1 ;;
      *) exit 1 ;;
    esac
    [ "$6" = "$source" ] || exit 1
    if scaffolding_is_agent_unit; then
      printf '%s' "$7" | grep -Eq '^[0-9]+ [0-9]+$' || exit 1
    fi
  done
}

scaffolding_manifest_field() {
  line=$1
  index=$2
  old_ifs=$IFS
  IFS='|'
  # shellcheck disable=SC2086
  set -- $line
  IFS=$old_ifs
  eval "printf '%s\n' \"\$$index\""
}

scaffolding_previous_type() {
  destination=$1
  if [ -L "$destination" ]; then
    printf '%s\n' symlink
  elif [ -f "$destination" ]; then
    printf '%s\n' file
  elif [ ! -e "$destination" ]; then
    printf '%s\n' absent
  else
    return 1
  fi
}

scaffolding_stage_previous() {
  transaction=$1
  manifest_tmp=$transaction/manifest
  backup_tmp=$transaction/$SCAFFOLDING_BACKUP_NAME
  mkdir -p "$backup_tmp" "$transaction/render"
  chmod 700 "$transaction" "$backup_tmp" "$transaction/render"

  (
    umask 077
    printf 'version=%s\n' "$(scaffolding_manifest_version)"
    printf '%s\n' "source_root=$SCAFFOLDING_ROOT"
    printf '%s\n' "source_sha=$(scaffolding_source_sha)"
    printf '%s\n' "created_at=$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    scaffolding_targets | while IFS='|' read -r name destination source; do
      previous_type=$(scaffolding_previous_type "$destination") || exit 1
      case $previous_type in
        absent)
          previous_ref=-
          ;;
        file)
          previous_ref=$SCAFFOLDING_BACKUP_NAME/$name.file
          cp -p "$destination" "$transaction/$previous_ref"
          ;;
        symlink)
          previous_ref=$SCAFFOLDING_BACKUP_NAME/$name.link
          readlink "$destination" > "$transaction/$previous_ref"
          ;;
      esac
      if scaffolding_is_agent_unit; then
        scaffolding_render_agent "$destination" > "$transaction/render/$name" || exit 1
        printf '%s\n' "entry|$name|$destination|$previous_type|$previous_ref|$source|$(cksum < "$transaction/render/$name")"
      else
        printf '%s\n' "entry|$name|$destination|$previous_type|$previous_ref|$source"
      fi
    done
  ) > "$manifest_tmp"
  chmod 600 "$manifest_tmp" "$backup_tmp"/* 2>/dev/null || :
}

scaffolding_manifest_entry() {
  name=$1
  grep -F "entry|$name|" "$SCAFFOLDING_MANIFEST"
}
