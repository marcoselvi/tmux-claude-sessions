#!/usr/bin/env bash
set -euo pipefail

pane_path="$1"
input="$2"
branch="${3:-}"

if [[ -z "$input" ]]; then
    tmux display-message "tcc: path is required"
    exit 1
fi

# --- Helper functions ---

is_git_url() {
    local s="$1"
    [[ "$s" =~ ^git@ ]] || [[ "$s" =~ ^https?://.+/.+ ]] || [[ "$s" =~ ^ssh:// ]]
}

is_git_repo() {
    git -C "$pane_path" rev-parse --is-inside-work-tree &>/dev/null
}

repo_name_from_url() {
    local url="$1"
    local name
    name="$(basename "$url")"
    name="${name%.git}"
    echo "$name"
}

sanitize_session_name() {
    local name="$1"
    name="${name//./-}"
    name="${name//:/-}"
    echo "$name"
}

# --- Step 0: Derive session name and check if it already exists ---

if is_git_url "$input"; then
    session_base="$(repo_name_from_url "$input")"
else
    session_base="$(basename "$input")"
fi
session="$(sanitize_session_name "$session_base")"

if tmux has-session -t "=$session" 2>/dev/null; then
    tmux switch-client -t "$session"
    exit 0
fi

# --- Step 1-3: Set up project directory ---

if is_git_url "$input"; then
    base_dir="${TCC_HOME:-$HOME}"
    project_dir="$base_dir/$session_base"
    if [[ -d "$project_dir" ]]; then
        tmux display-message "tcc: $project_dir already exists but no session '$session' found"
        exit 1
    fi
    if [[ -n "$branch" ]]; then
        git clone -b "$branch" "$input" "$project_dir"
    else
        git clone "$input" "$project_dir"
    fi

elif is_git_repo; then
    worktree_branch="${branch:-$(basename "$input")}"
    # Resolve relative paths against the pane's working directory
    if [[ "$input" != /* ]]; then
        input="$pane_path/$input"
    fi
    if [[ -e "$input" ]]; then
        tmux display-message "tcc: $input already exists but no session '$session' found"
        exit 1
    fi
    git -C "$pane_path" worktree add "$input" -b "$worktree_branch"
    project_dir="$(realpath "$input")"

else
    # Resolve relative paths against the pane's working directory
    if [[ "$input" != /* ]]; then
        input="$pane_path/$input"
    fi
    if [[ -e "$input" ]]; then
        tmux display-message "tcc: $input already exists but no session '$session' found"
        exit 1
    fi
    mkdir -p "$input"
    project_dir="$(realpath "$input")"
    git init -C "$project_dir" -b "${branch:-main}"
fi

# --- Create tmux session with 3 windows ---

tmux new-session -d -s "$session" -n "claude" -c "$project_dir" "bash -c 'claude --effort high; exec $SHELL'"
tmux new-window -t "$session" -n "nvim" -c "$project_dir" "bash -c 'nvim; exec $SHELL'"
tmux new-window -t "$session" -n "shell" -c "$project_dir"

tmux switch-client -t "$session"
