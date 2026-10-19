-- new_session_from_template: open a new session shaped like the "dotfiles" session
-- (three tabs: shell/shell/lazygit split, opencode, nvim) with every pane
-- started in the given directory. Works from any session, including a blank one.
--
--   rex do new_session_from_template path=~/code/project
--
-- Without a path, a prompt asks for one: in a split below the current pane, or
-- in a throwaway session when there is no pane (no session yet).

local SHELL_FLAVOR = "com.superlogical.terminal.shell"

-- Each pane types its command into a shell, so quitting the program leaves a
-- shell behind. A nil command is a plain shell.
local function pane(path, command)
	local options = { cwd = path }
	if command then
		options.initial_input = command .. "\n"
	end
	return rex.layout.block({ flavor = SHELL_FLAVOR, options = options })
end

local function template(path)
	return {
		{
			layout = rex.layout.horizontal(
				0.4,
				rex.layout.vertical(0.5, pane(path), pane(path)),
				pane(path, "lazygit")
			),
		},
		{ layout = pane(path, "opencode") },
		{ layout = pane(path, "nvim") },
	}
end

local function expand(path)
	if path == "~" or path:sub(1, 2) == "~/" then
		path = (os.getenv("HOME") or "") .. path:sub(2)
	end
	return (path:gsub("/+$", ""))
end

-- $REX_SESSION is the session holding the prompt pane. When that session was
-- only created for the prompt ($1 = temp), it is removed afterwards.
local PROMPT_SCRIPT = [[
printf 'Directory for the new session (empty for %s): ' "$PWD"
read -r path
rex do -s "$REX_SESSION" new_session_from_template path="${path:-$PWD}" ||
	{ printf '\nPress Enter to close'; read -r _; }
[ "$1" != temp ] || rex kill "$REX_SESSION" >/dev/null 2>&1
]]

local function must(value, err)
	if value == nil then
		error(err, 0)
	end
	return value
end

local function prompt_pane(temp)
	return rex.layout.block({
		flavor = SHELL_FLAVOR,
		options = { command = { "sh", "-c", PROMPT_SCRIPT, "sh", temp and "temp" or "" } },
	})
end

local function prompt_for_path(ctx)
	if ctx.block_id == nil then
		local created = must(rex.call("session.create", {
			label = "new-session",
			initial_windows = { { layout = prompt_pane(true) } },
		}))
		rex.client.queue("session.select", { session_id = created.session_id })
		return
	end
	must(rex.session.new_split({
		anchor_block_id = ctx.block_id,
		direction = "vertical",
		side = "after",
		ratio = 0.75,
		focus = true,
		layout = prompt_pane(false),
	}))
end

local function create(args)
	local path = expand(args.path)
	if path:sub(1, 1) ~= "/" then
		error("Path must be absolute or start with ~: " .. args.path, 0)
	end
	local result = rex.exec({ "test", "-d", path })
	if result == nil or result.code ~= 0 then
		error("Not a directory: " .. path, 0)
	end

	local created = must(rex.call("session.create", {
		label = path:match("([^/]+)$") or "session",
		initial_windows = template(path),
	}))
	local switched = pcall(rex.client.queue, "session.select", { session_id = created.session_id })
	return { session_id = created.session_id, path = path, switched = switched }
end

rex.action({
	name = "new_session_from_template",
	title = "New session from template",
	description = "Open a new session from the dotfiles layout template (shells, lazygit, opencode, nvim) rooted in a directory.",
	category = "Global",
	keywords = "new session template layout project directory path",
	args = { path = "string?" },
	run = function(ctx, args)
		if args.path == nil or args.path == "" then
			return prompt_for_path(ctx)
		end
		return create(args)
	end,
})
