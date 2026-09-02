#!/bin/sh

scaffolding_source_sha() {
  git -C "$SCAFFOLDING_ROOT" rev-parse HEAD 2>/dev/null || printf '%s\n' unknown
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

scaffolding_manifest_is_valid() {
  scaffolding_state_path_is_safe || return 1
  [ -f "$SCAFFOLDING_MANIFEST" ] || return 1
  grep -Fqx "version=$(scaffolding_manifest_version)" "$SCAFFOLDING_MANIFEST" || return 1
  grep -Fqx "source_root=$SCAFFOLDING_ROOT" "$SCAFFOLDING_MANIFEST" || return 1
  grep -Eq '^source_sha=[0-9a-f]{40}$|^source_sha=unknown$' "$SCAFFOLDING_MANIFEST" || return 1
  grep -Eq '^created_at=[0-9]{4}-[0-9]{2}-[0-9]{2}T' "$SCAFFOLDING_MANIFEST" || return 1

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
