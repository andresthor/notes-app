#!/usr/bin/env bash

load_config() {
  local config_paths=(
    "${XDG_CONFIG_HOME:-$HOME/.config}/notes/config"
    "$HOME/.notes/config"
    "${SCRIPT_DIR}/../config"
  )

  for config_file in "${config_paths[@]}"; do
    if [[ -f "${config_file}" ]]; then
      source "${config_file}"
      return 0
    fi
  done

  echo "Error: No configuration file found" >&2
  return 1
}
