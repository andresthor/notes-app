#!/usr/bin/env bash

set -euo pipefail

# Default installation directory
PREFIX="${PREFIX:-$HOME/.local}"

uninstall() {
  local exit_code=0

  echo "Uninstalling notes program..."

  # Remove executable
  if [[ -f "${PREFIX}/bin/notes" ]]; then
    rm "${PREFIX}/bin/notes" || {
      echo "Error: Failed to remove executable" >&2
      exit_code=1
    }
  fi

  # Remove library files
  if [[ -d "${PREFIX}/lib/notes" ]]; then
    rm -r "${PREFIX}/lib/notes" || {
      echo "Error: Failed to remove library files" >&2
      exit_code=1
    }
  fi

  # Remove templates
  if [[ -d "${PREFIX}/share/notes/templates" ]]; then
    rm -r "${PREFIX}/share/notes/templates" || {
      echo "Error: Failed to remove templates" >&2
      exit_code=1
    }
  fi
  # Clean up empty share/notes directory if it exists
  if [[ -d "${PREFIX}/share/notes" ]] && [[ -z "$(ls -A "${PREFIX}/share/notes")" ]]; then
    rmdir "${PREFIX}/share/notes" || true
  fi

  # Offer to remove configuration
  if [[ -f "${HOME}/.config/notes/config" ]]; then
    read -r -p "Do you want to remove the configuration file? [y/N] " response
    if [[ "${response}" =~ ^[Yy]$ ]]; then
      rm "${HOME}/.config/notes/config" || {
        echo "Error: Failed to remove configuration file" >&2
        exit_code=1
      }
      # Clean up empty config directory if it exists
      if [[ -d "${HOME}/.config/notes" ]] && [[ -z "$(ls -A "${HOME}/.config/notes")" ]]; then
        rmdir "${HOME}/.config/notes" || true
      fi
    fi
  fi

  if [[ $exit_code -eq 0 ]]; then
    echo "Uninstallation complete. Your notes and data remain untouched."
    echo "You may manually remove your notes directory if desired."
  else
    echo "Uninstallation completed with some errors."
  fi

  return $exit_code
}

# Show a confirmation prompt before proceeding
read -r -p "Are you sure you want to uninstall the notes program? [y/N] " response
if [[ "${response}" =~ ^[Yy]$ ]]; then
  uninstall
else
  echo "Uninstallation cancelled."
  exit 0
fi
