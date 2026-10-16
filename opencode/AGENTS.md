# Global instructions

## Worktrees inside Rex

When `$REX_SESSION` is set, you're running in a Rex terminal. In that case,
any request to create a worktree, or to do work in a new or separate worktree
(e.g. "create a new worktree to fix X"), must go through the `rex-worktree`
skill, not the built-in `worktree_create` and `session_move` tools. The skill
also creates the branch, mirrors the Rex session with its running programs,
and hands the task to a new agent in that worktree.
