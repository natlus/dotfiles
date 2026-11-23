-- bindings
rex.bind("ctrl+s>f", "pane.zoom")
rex.bind("ctrl+s>v", "pane.split", { direction = "right" })
rex.bind("ctrl+s>s", "pane.split", { direction = "down" })
rex.bind("cmd+[", "pane.focus_previous")
rex.bind("cmd+]", "pane.focus_next")
rex.bind("ctrl+[", "pane.focus_previous")
rex.bind("ctrl+]", "pane.focus_next")
rex.bind("ctrl+s>m", "pane.minimize_all_floating")

rex.action({
	name = "goto_session",
	title = "Go to Session by Index",
	args = { index = "integer" },
	run = function(ctx, args)
		local result, err = rex.call("session.list")
		if err ~= nil then
			error(err, 0)
		end
		local session = (result.sessions or {})[args.index]
		if session == nil then
			return
		end
		rex.client.queue("session.select", { session_id = session.session_id })
	end,
})

for i = 1, 9 do
	rex.bind("ctrl+s>" .. i, "goto_session", { index = i })
end

rex.mode("resize", { exclusive = true })
rex.bind("ctrl+s>r", "client.mode.enter", { name = "resize" })

rex.bind("resize/left", "pane.resize", { direction = "left" })
rex.bind("resize/right", "pane.resize", { direction = "right" })
rex.bind("resize/up", "pane.resize", { direction = "up" })
rex.bind("resize/down", "pane.resize", { direction = "down" })
rex.bind("resize/enter", "client.mode.exit")

require("worktree_mirror")
rex.bind("ctrl+s>w", "worktree_mirror")

require("open_project")
rex.bind("ctrl+s>n", "open_project")

require("open_worktree")

-- automatically restore sessions using rexurrect
--
do
	local r = rex.exec({ "/opt/homebrew/bin/rexurrect", "auto-restore" }, {
		env = {
			REXURRECT_STATE_DIR = "/Users/jessul01/.local/state/rexurrect",
			REXURRECT_CONFIG = "/Users/jessul01/.config/rexurrect/config.toml",
		},
	})
	if r then
		io.stderr:write(r.stderr)
	end
end
