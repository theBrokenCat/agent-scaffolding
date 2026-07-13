#!/bin/sh

scaffolding_source_sha() {
  git -C "$SCAFFOLDING_ROOT" rev-parse HEAD 2>/dev/null || printf '%s\n' unknown
}

scaffolding_manifest_exists() {
  [ -e "$SCAFFOLDING_MANIFEST" ] || [ -L "$SCAFFOLDING_MANIFEST" ]
}

scaffolding_manifest_is_valid() {
  scaffolding_state_path_is_safe || return 1
  [ -f "$SCAFFOLDING_MANIFEST" ] || return 1
  grep -Fqx 'version=2' "$SCAFFOLDING_MANIFEST" || return 1
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
      file) [ "$5" = "backups/$name.file" ] && [ -f "$SCAFFOLDING_STATE_DIR/$5" ] || exit 1 ;;
      symlink) [ "$5" = "backups/$name.link" ] && [ -f "$SCAFFOLDING_STATE_DIR/$5" ] || exit 1 ;;
      *) exit 1 ;;
    esac
    [ "$6" = "$source" ] || exit 1
  done
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
  backup_tmp=$transaction/backups
  mkdir -p "$backup_tmp"
  chmod 700 "$transaction" "$backup_tmp"

  (
    umask 077
    printf '%s\n' 'version=2'
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
          previous_ref=backups/$name.file
          cp -p "$destination" "$transaction/$previous_ref"
          ;;
        symlink)
          previous_ref=backups/$name.link
          readlink "$destination" > "$transaction/$previous_ref"
          ;;
      esac
      printf '%s\n' "entry|$name|$destination|$previous_type|$previous_ref|$source"
    done
  ) > "$manifest_tmp"
  chmod 600 "$manifest_tmp" "$backup_tmp"/* 2>/dev/null || :
}

scaffolding_manifest_entry() {
  name=$1
  grep -F "entry|$name|" "$SCAFFOLDING_MANIFEST"
}
