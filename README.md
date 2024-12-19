# notes-app

A bash script `notes` that has the following functions:

## `notes new <note title>`
  - creates a new `.md` file `~/notes/misc/<title>.md`

## `notes search`
  - runs the existing shell function `open_notes_with_fzf`

## `notes daily`
  - checks if `~/notes/daily/YYYY-MM-DD-<Weekday>.md` exists
  - opens it with vim if it exists
  - otherwise
    - copies the template in `~/notes/daily/00-template.md` to the above
    location
    - prepends `# Daily Notes - Weekday MONTH DD<th|nd> YYYY\n`
    - and opens with vim

## `notes bucket <optional free text>`
  - checks if `~/notes/bucket/YYYY/MM.md` exists
  - creates it and required dir if it does not exist
  - appends day and timestamp `[MM-DD HH:MM]` (note space)
  - if there is free text, adds it to the end of the file
  - if there is no free text, opens it with vim and cursor at end of file
