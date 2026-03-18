#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

tmux bind-key C command-prompt -p "path:","branch (optional):" \
  "run-shell \"$CURRENT_DIR/scripts/create_session.sh '#{pane_current_path}' '%1' '%2'\""
