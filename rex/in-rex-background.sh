#!/bin/sh
# Exits 0 when the caller is a Claude Code background session (claude --bg or
# one started from `claude agents`) and the Rex server answers. Such sessions
# run in the Claude daemon, not in a Rex pane: their REX_SESSION and REX_BLOCK
# are inherited from whichever pane started the daemon, so leave them out of
# rex calls (env -u REX_SESSION -u REX_BLOCK rex ...).

# Not every kind of background job sets SESSION_KIND, but all set CLAUDE_JOB_DIR.
[ "$CLAUDE_CODE_SESSION_KIND" = bg ] || [ -n "$CLAUDE_JOB_DIR" ] || exit 1

rex=rex
command -v rex >/dev/null 2>&1 || rex="$REX_BIN_DIR/rex"
[ -x "$rex" ] || command -v "$rex" >/dev/null 2>&1 || exit 1

env -u REX_SESSION -u REX_BLOCK "$rex" whoami --json >/dev/null 2>&1
