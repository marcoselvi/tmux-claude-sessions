# tmux-claude-sessions

Create tmux development sessions with [Claude](https://claude.ai), nvim, and a shell. Each session gets three named windows:

1. **claude** — `claude --effort high`
2. **nvim** — `nvim`
3. **shell** — plain shell

The tool detects your context and acts accordingly:

- **Git URL** — clones the repo into `$TCC_HOME` (default: `$HOME`)
- **Inside a git repo** — creates a new worktree
- **Otherwise** — creates a new directory and runs `git init`

If a session with the same name already exists, it switches to it.

## Tmux plugin

### Install with TPM

Add to your `~/.tmux.conf`:

```tmux
set -g @plugin 'marcoselvi/tmux-claude-sessions'
```

Reload tmux and install with `prefix + I`.

### Install manually

```bash
git clone https://github.com/marcoselvi/tmux-claude-sessions.git ~/.tmux/plugins/tmux-claude-sessions
```

Add to your `~/.tmux.conf`:

```tmux
run-shell ~/.tmux/plugins/tmux-claude-sessions/tmux-claude-sessions.tmux
```

### Usage

Press `prefix + C`. You'll be prompted for:

1. **path** — a git URL, directory path, or project name
2. **branch** (optional) — press Enter to skip

## Standalone script

### Install

Copy or symlink `tcc.sh` somewhere on your `$PATH`:

```bash
ln -s /path/to/tmux-claude-sessions/tcc.sh /usr/local/bin/tcc
```

### Usage

```
tcc <path-or-url> [branch]
```

### Examples

```bash
tcc https://github.com/user/repo.git          # clone and open session
tcc https://github.com/user/repo.git develop   # clone a specific branch
tcc ../my-feature                              # new worktree (from a git repo)
tcc my-project                                 # new directory + git init
tcc my-project feature-branch                  # new directory on a named branch
```

### Environment

| Variable   | Description                          | Default |
|------------|--------------------------------------|---------|
| `TCC_HOME` | Base directory for cloned repos      | `$HOME` |
