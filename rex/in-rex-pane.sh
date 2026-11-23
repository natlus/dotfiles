#!/bin/sh
# Exits 0 when the caller runs in a live Rex pane. REX_* variables alone aren't
# enough: Claude Code background jobs inherit them from whichever pane started
# the daemon, and that pane may be gone.

[ -n "$REX_BLOCK" ] || exit 1
[ "$CLAUDE_CODE_SESSION_KIND" = bg ] && exit 1

rex=rex
command -v rex >/dev/null 2>&1 || rex="$REX_BIN_DIR/rex"
[ -x "$rex" ] || command -v "$rex" >/dev/null 2>&1 || exit 1

[ "$("$rex" whoami --json 2>/dev/null | jq -r '.block_id // empty')" = "$REX_BLOCK" ]
