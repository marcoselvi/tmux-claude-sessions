#!/usr/bin/env bash
set -euo pipefail

# --- Argument parsing ---
if [[ $# -lt 1 ]]; then
    echo "Usage: tcc <path-or-url> [branch]" >&2
    exit 1
fi

input="$1"
branch="${2:-}"

# --- Helper functions ---

is_git_url() {
    local s="$1"
    [[ "$s" =~ ^git@ ]] || [[ "$s" =~ ^https?://.+/.+ ]] || [[ "$s" =~ ^ssh:// ]]
}

is_git_repo() {
    git rev-parse --is-inside-work-tree &>/dev/null
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
    # tmux doesn't allow dots or colons in session names
    name="${name//./-}"
    name="${name//:/-}"
    echo "$name"
}

switch_or_attach() {
    local session="$1"
    if [[ -n "${TMUX:-}" ]]; then
        tmux switch-client -t "$session"
    else
        tmux attach-session -t "$session"
    fi
}

# --- Step 0: Derive session name and check if it already exists ---

if is_git_url "$input"; then
    session_base="$(repo_name_from_url "$input")"
else
    session_base="$(basename "$input")"
fi
session="$(sanitize_session_name "$session_base")"

if tmux has-session -t "=$session" 2>/dev/null; then
    switch_or_attach "$session"
    exit 0
fi

# --- Step 1-3: Set up project directory ---

if is_git_url "$input"; then
    # Clone into TCC_HOME (or $HOME)
    base_dir="${TCC_HOME:-$HOME}"
    project_dir="$base_dir/$session_base"
    if [[ -d "$project_dir" ]]; then
        echo "Error: $project_dir already exists but no tmux session '$session' found" >&2
        exit 1
    fi
    if [[ -n "$branch" ]]; then
        git clone -b "$branch" "$input" "$project_dir"
    else
        git clone "$input" "$project_dir"
    fi

elif is_git_repo; then
    # Create a worktree
    worktree_branch="${branch:-$(basename "$input")}"
    if [[ -e "$input" ]]; then
        echo "Error: $input already exists but no tmux session '$session' found" >&2
        exit 1
    fi
    git worktree add "$input" -b "$worktree_branch"
    project_dir="$(realpath "$input")"

else
    # Create a new project directory
    if [[ -e "$input" ]]; then
        echo "Error: $input already exists but no tmux session '$session' found" >&2
        exit 1
    fi
    mkdir -p "$input"
    project_dir="$(realpath "$input")"
    git init -C "$project_dir" -b "${branch:-main}"
fi

# --- Create tmux session with 3 windows ---

tmux new-session -d -s "$session" -c "$project_dir"
tmux send-keys -t "$session:1" "claude --effort high" Enter

tmux new-window -t "$session" -c "$project_dir"
tmux send-keys -t "$session:2" "nvim" Enter

tmux new-window -t "$session" -c "$project_dir"

# Attach or switch
switch_or_attach "$session"
