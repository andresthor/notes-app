#!/usr/bin/env bash

set -euo pipefail

# Default installation directory
PREFIX="${PREFIX:-$HOME/.local}"

install() {
  # Create directories
  mkdir -p "${PREFIX}/bin"
  mkdir -p "${PREFIX}/lib/notes"
  mkdir -p "${PREFIX}/share/notes/templates"
  mkdir -p "${HOME}/.config/notes"

  # Install executable
  cp bin/notes "${PREFIX}/bin/"
  chmod +x "${PREFIX}/bin/notes"

  # Install library files
  cp lib/* "${PREFIX}/lib/notes/"

  # Install templates
  cp share/templates/* "${PREFIX}/share/notes/templates/"

  # Install config if it doesn't exist
  if [[ ! -f "${HOME}/.config/notes/config" ]]; then
    cp config.example "${HOME}/.config/notes/config"
  fi

  echo "Installation complete. Please add ${PREFIX}/bin to your PATH if it's not already there."
}

install
