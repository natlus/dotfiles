# Global instructions

## Working inside Rex

These rules apply only when you're running in a live Rex pane, that is when
`~/.config/rex/in-rex-pane.sh` exits 0. `$REX_SESSION` being set isn't enough:
Claude Code background jobs inherit stale `REX_*` variables from the pane that
started the daemon. If the check fails, ignore Rex and use your built-in tools,
with one exception: in a Claude Code background session where
`~/.config/rex/in-rex-background.sh` exits 0, worktree requests still go
through the `rex-worktree` skill below, which has a flow for background
sessions.

- Before running any `rex` command (opening tabs, splitting panes, running or
  reading other terminals), load the `rex` skill and follow its guide.
- Any request to create a worktree, or to do work in a new or separate
  worktree (e.g. "create a new worktree to fix X"), must go through the
  `rex-worktree` skill. Don't use built-in worktree tools for this: not
  OpenCode's `worktree_create` and `session_move`, not Claude Code's
  `EnterWorktree`, and not `git worktree add` by hand. The skill also creates
  the branch and moves your own conversation into that worktree, keeping its
  context, unless the user asks for a new agent. The user picks where it
  opens (floating pane, tab, new session, or not at all) in a Rex prompt the
  skill's action shows, so don't choose for them.
