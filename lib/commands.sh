#!/usr/bin/env bash

notes() {
  case "$1" in
  new)
    new_note "${@:2}"
    ;;
  daily)
    daily_note "${@:2}"
    ;;
  bucket)
    bucket_note "${@:2}"
    ;;
  read)
    shift
    read_notes "${@:-previous}"
    ;;
  search)
    search_notes_with_fzf "${@:2}"
    ;;
  find)
    shift
    find_notes_with_fzf "${@:-.}"
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

EOF
}

read_notes() {
  case "$1" in
  bucket) bucket_read_note ;;
  daily) daily_note 0 ;;
  previous) ls -t ${NOTES_DIR}/*/* | head -n 1 | xargs -n 1 "$EDITOR" ;;
  *)
    echo "'notes read $1' is not a valid command" >&2
    return 1
    ;;
  esac
}

new_note() {
  if [[ -z "${1:-}" ]]; then
    echo "Missing note title" >&2
    return 1
  fi

  local note_title=$1
  local note_path=$NOTES_MISC_DIR/${note_title}.md

  if [[ -f $note_path ]]; then
    echo "Note already exists" >&2
    return 1
  fi

  "$EDITOR" $note_path
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
  local entries_past="${1:-}"
  if [[ ! -z "$entries_past" || "$entries_past" = 0 ]]; then
    if ! [[ "$entries_past" =~ ^[-+]?[0-9]+$ ]]; then
      echo "Error: Argument must be a number" >&2
      return 1
    fi

    local entry=$((1 - $entries_past))
    if [[ $entries_past > 0 ]]; then
      entry=$((1 + $entries_past))
    fi
    entry_name=$(ls -t $NOTES_DAILY_DIR/ | head -n $entry | tail -n 1)
    "$EDITOR" "$NOTES_DAILY_DIR/$entry_name"
  else
    tmp_file=$(mktemp) || {
      echo "Failed to create temp file" >&2
      return 1
    }
    trap 'rm -f "${tmp_file}"' EXIT

    local note_path=$NOTES_DAILY_DIR/$(date +"%Y-%m-%d-%A").md

    if [[ -f $note_path ]]; then
      "$EDITOR" $note_path
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

      "$EDITOR" $note_path
    fi
  fi
}

bucket_note() {
  local note_path=$NOTES_BUCKET_DIR/$(date +"%Y/%m").md

  bucket_note_create_if_not_exist "$note_path"
  timestamp=$(printf -- "- [ %s ]" "$(date +"%Y-%m-%d %H:%M")")
  note="$timestamp ${1:-}"
  bucket_open "$note_path" $note
}

bucket_read_note() {
  local note_path=$NOTES_BUCKET_DIR/$(date +"%Y/%m").md

  bucket_note_create_if_not_exist "$note_path"
  bucket_open "$note_path"
}

bucket_note_create_if_not_exist() {
  if [[ ! -f "$1" ]]; then
    mkdir -p "$(dirname "$1")" || {
      echo "Error: Could not create directory" >&2
      return 1
    }
    echo "# Bucket notes $(date +"%Y-%m")\n" >$1
  fi
}

bucket_open() {
  note="${2:-}"
  if [[ ! -z "$note" ]]; then
    note="\"normal a\<CR>$2\""
  fi
  $EDITOR '+ normal G$' -c ":exe ${note}" "$1"
}

search_notes_with_fzf() {
  rg --column --no-heading "${1:-.}" $NOTES_DIR |
    fzf --delimiter : \
      --preview 'bat --color=always --highlight-line {2} {1}' \
      --preview-window '~3,+{2}+3/2' \
      --select-1 |
    awk -F: '{print "+" $2, $1}' |
    xargs -n 2 nvim
}

find_notes_with_fzf() {
  fd -t f -I -L "$1" $NOTES_DIR |
    fzf --preview 'bat --color=always {}' --select-1 |
    awk -F: '{print "+" $2, $1}' |
    xargs -n 2 nvim
}
