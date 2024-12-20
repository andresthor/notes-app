#!/usr/bin/env bash

notes() {
  case "$1" in
  new)
    shift
    new_note "$@"
    ;;
  daily)
    shift
    daily_note "$@"
    ;;
  bucket)
    shift
    bucket_note "$@"
    ;;
  read)
    shift
    read_notes "$@"
    ;;
  search)
    shift
    search_notes_with_fzf "$@"
    ;;
  find)
    shift
    find_notes_with_fzf "$@"
    ;;
  help | --help | -h) show_help ;;
  *)
    show_help
    return 1
    ;;
  esac
}

show_help() {
  cat <<EOF
Usage: notes COMMAND [OPTIONS]

Commands:
    new     Create a new note
    daily   Manage daily notes
    bucket  Manage bucket notes
    read    Read recent notes
    search  Search through notes
    find    Find notes
    help    Show this help message

For more information about a command:
    notes COMMAND --help
EOF
}

read_notes() {
  case "$1" in
  "${NOTES_CMD_BUCKET}") bucket_read_note "$2" ;;
  "${NOTES_CMD_DAILY}") daily_note 0 ;;
  *) ls -t ${NOTES_BASE_DIR}/*/* | head -n 1 | xargs -n 1 nvim ;;
  esac
}

new_note() {
  if [[ -z "$1" ]]; then
    echo "Missing note title" >&2
    return 1
  fi

  local note_title=$1
  local note_path=$NOTES_MISC_DIR/${note_title}.md

  if [[ -f $note_path ]]; then
    echo "Note already exists" >&2
    return 1
  fi

  touch $note_path
  vim $note_path
}

date_with_suffix() {
  day=$(date +"%-d")
  case $day in
  1 | 21 | 31) suffix="st" ;;
  2 | 22) suffix="nd" ;;
  3 | 23) suffix="rd" ;;
  *) suffix="th" ;;
  esac
  echo "$(date +"%A %B $day")${suffix} $(date +"%Y")"
}

daily_note() {
  if [[ ! -z $1 || $1 = 0 ]]; then
    if ! [[ "$1" =~ ^[-+]?[0-9]+$ ]]; then
      echo "Error: Argument must be a number" >&2
      return 1
    fi

    local entry=$((1 - $1))
    if [[ $1 > 0 ]]; then
      entry=$((1 + $1))
    fi
    entry_name=$(ls -t $NOTES_DAILY_DIR/ | head -n $entry | tail -n 1)
    vim "$NOTES_DAILY_DIR/$entry_name"
  else
    local tmp_file
    tmp_file=$(mktemp) || {
      echo "Failed to create temp file" >&2
      return 1
    }
    trap 'rm -f "${tmp_file}"' EXIT

    local note_path=$NOTES_DAILY_DIR/$(date +"%Y-%m-%d-%A").md

    if [[ -f $note_path ]]; then
      vim $note_path
    else
      last_daily="$(ls -t "${NOTES_DAILY_DIR}/" | grep -v "template" | head -n 1)"
      cp -f $NOTES_DAILY_TEMPLATE $note_path
      sed -i '' "s/TEMPLATE_DATE/$(date_with_suffix)/" $note_path

      sed -n '/^### Carry-over$/,/^## Log$/p' "$NOTES_DAILY_DIR/$last_daily" | sed '1d;$d;/^$/d' >$tmp_file
      sed -i '' "/TEMPLATE_CARRY_OVER/{
      r $tmp_file
      d
      }" $note_path
      rm $tmp_file

      vim $note_path
    fi
  fi
}

bucket_note() {
  local note_path=$NOTES_BUCKET_DIR/$(date +"%Y/%m").md

  bucket_note_create_if_not_exist "$note_path"
  bucket_append_note "$note_path" "$*"
  bucket_open "$note_path" "$1"
}

bucket_read_note() {
  local note_path=$NOTES_BUCKET_DIR/$(date +"%Y/%m").md

  bucket_note_create_if_not_exist "$note_path"
  bucket_open "$note_path" "$1"
}

bucket_note_create_if_not_exist() {
  if [[ ! -f $1 ]]; then
    mkdir -p "$(dirname "${1}")" || {
      echo "Error: Could not create directory" >&2
      return 1
    }
    echo "# Bucket notes $(date +"%Y-%m")\n" >$1
  fi
}

bucket_append_note() {
  if [[ "$2" != "${NOTES_BUCKET_CMD_READ}" ]]; then
    {
      printf -- "- [ %s ] " "$(date +"%Y-%m-%d %H:%M")"
      printf "%s\n" "${@:2}"
    } >>"$1" || {
      echo "Error: Failed to write to note" >&2
      return 1
    }
  fi
}

bucket_open() {
  if [[ -z $2 || $2 == $NOTES_BUCKET_CMD_READ ]]; then
    vim "+ normal GA" $1
  fi
}
