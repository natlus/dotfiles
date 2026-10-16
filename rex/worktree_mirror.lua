-- worktree_mirror: create a git worktree on a new branch from the current
-- pane's HEAD, then open a new session that mirrors this session's tabs,
-- splits and running programs inside the worktree, and switch to it.
--
--   rex do worktree_mirror name=my-feature
--   rex do worktree_mirror --args '{"name":"my-feature","task":"Fix …"}'
--
-- Without a name, a prompt opens below the current pane asking for one.
-- With a task, the mirrored agent pane starts with it as its first prompt.

local TERMINAL = "com.superlogical.terminal"
local SHELL_FLAVOR = "com.superlogical.terminal.shell"
local WORKTREES_DIR = ".claude/worktrees"
-- Typed into each mirrored pane inside the repo before its command runs.
local SETUP_COMMAND = "~/.config/rex/worktree-setup.sh"
-- How each agent CLI takes an initial prompt, keyed by process name.
local AGENT_TASK_FLAGS = { claude = "", codex = "", opencode = "--prompt " }

local function quote(s)
	return "'" .. (s:gsub("'", "'\\''")) .. "'"
end

-- Runs a shell command and returns its trimmed output and exit status.
local function run(cmd)
	local f = io.popen(cmd .. " 2>&1; printf '\\n%s' $?")
	local out = f:read("*a")
	f:close()
	local body, code = out:match("^(.*)\n(%d+)$")
	return (body or out):gsub("%s+$", ""), tonumber(code) or 1
end

local function git(dir, args)
	local out, code = run("git -C " .. quote(dir) .. " " .. args)
	if code ~= 0 then
		return nil, out
	end
	return out
end

local function must(value, err)
	if value == nil then
		error(err, 0)
	end
	return value
end

local function process_of(block_id)
	local proc = rex.block.call(TERMINAL, "process", { block_id = block_id })
	local fg = proc and proc.foreground or {}
	-- Some programs (e.g. top) hide their cwd; fall back to the shell's.
	if fg.cwd == nil then
		for _, ancestor in ipairs(proc and proc.ancestors or {}) do
			if ancestor.cwd then
				fg.cwd = ancestor.cwd
				break
			end
		end
	end
	return fg
end

-- The full command line of a pane's foreground program, or nil when the pane
-- sits at a shell prompt (login shells have an argv0 starting with "-").
local function command_of(fg)
	if fg.pid == nil or (fg.argv0 or ""):sub(1, 1) == "-" then
		return nil
	end
	local cmd, code = run("ps -o command= -p " .. fg.pid)
	if code ~= 0 or cmd == "" then
		return nil
	end
	-- Don't re-run whatever triggered this action.
	if cmd:match("^rex%s") or cmd:match("/rex%s") then
		return nil
	end
	return cmd
end

-- The Rex app doesn't draw floating layers yet, so the prompt opens as a
-- split below the current pane. Splitting cancels the tab's zoom, so the
-- zoomed pane is passed along to be restored afterwards and in the mirror.
local function prompt_for_name(ctx)
	local zoomed = ""
	for _, w in ipairs(must(rex.session.view({})).windows or {}) do
		for _, layer in ipairs(w.layers or {}) do
			for _, b in ipairs(layer.blocks or {}) do
				if b.block_id == ctx.block_id then
					zoomed = w.zoomed_block_id or ""
				end
			end
		end
	end
	local script = [[
printf 'New worktree branch name (empty to cancel): '
read -r name
if [ -n "$name" ]; then
	rex do -s "$1" -b "$2" worktree_mirror \
		--args "{\"name\":\"$name\",\"prompt_block\":\"$REX_BLOCK\",\"zoomed_block\":\"$3\"}" ||
		{ printf '\nPress Enter to close'; read -r _; }
fi
rex focus -s "$1" "$2" >/dev/null 2>&1
[ -z "$3" ] || rex zoom -s "$1" "$3" --on >/dev/null 2>&1
]]
	must(rex.session.new_split({
		anchor_block_id = ctx.block_id,
		direction = "vertical",
		side = "after",
		ratio = 0.75,
		focus = true,
		layout = {
			block = {
				flavor = SHELL_FLAVOR,
				options = { command = { "sh", "-c", script, "sh", ctx.session_id, ctx.block_id, zoomed } },
			},
		},
	}))
end

local function mirror(ctx, args)
	local name = args.name
	local prompt_block = args.prompt_block
	local zoomed_block = args.zoomed_block ~= "" and args.zoomed_block or nil
	local source_block = must(ctx.block_id, "worktree_mirror needs a pane to start from")
	local source_process = process_of(source_block)
	local source_cwd = must(source_process.cwd, "Could not read the pane's working directory")
	local source_root = must(git(source_cwd, "rev-parse --show-toplevel"))

	local common_dir = must(git(source_root, "rev-parse --path-format=absolute --git-common-dir"))
	local main_root = common_dir:gsub("/%.git/?$", "")
	local worktree = main_root .. "/" .. WORKTREES_DIR .. "/" .. name

	must(git(source_root, "check-ref-format --branch " .. quote(name)))
	must(git(source_root, "worktree add -b " .. quote(name) .. " " .. quote(worktree)))

	-- Gitignored env files at the repo root (e.g. .env.local) don't come with
	-- the checkout.
	local env_files = git(source_root, "ls-files --others --ignored --exclude-standard -- '.env*'") or ""
	for file in env_files:gmatch("[^\n]+") do
		local target = worktree .. "/" .. file
		run("mkdir -p " .. quote(target:match("^(.*)/")) .. " && cp -p " .. quote(source_root .. "/" .. file) .. " " .. quote(target))
	end

	local function remap(cwd)
		if cwd and git(cwd, "rev-parse --show-toplevel") == source_root then
			return worktree .. cwd:sub(#source_root + 1), true
		end
		return cwd or worktree, false
	end

	-- The task goes to the copy of the agent that asked for the worktree, or
	-- to the first agent pane when the request came from somewhere else.
	local task = args.task ~= "" and args.task or nil
	local task_agent
	local source_is_agent = AGENT_TASK_FLAGS[source_process.name or ""] ~= nil
	local function with_task(block, fg, cmd)
		local flag = AGENT_TASK_FLAGS[fg.name or ""]
		if not (task and cmd and flag) or task_agent then
			return cmd
		end
		if source_is_agent and block.block_id ~= source_block then
			return cmd
		end
		task_agent = fg.name
		return cmd .. " " .. flag .. quote(task)
	end

	local function pane(block)
		if block.creator_name ~= TERMINAL then
			return { flavor = SHELL_FLAVOR, options = { cwd = worktree, initial_input = SETUP_COMMAND .. "\n" } }
		end
		local fg = process_of(block.block_id)
		local cwd, in_repo = remap(fg.cwd)
		local steps = {}
		if in_repo then
			table.insert(steps, SETUP_COMMAND)
		end
		table.insert(steps, with_task(block, fg, command_of(fg)))
		local options = { cwd = cwd }
		if #steps > 0 then
			options.initial_input = table.concat(steps, " && ") .. "\n"
		end
		return { flavor = block.flavor, options = options }
	end

	local view = must(rex.session.view({}))
	local windows, old_ids = {}, {}
	for _, w in ipairs(view.windows or {}) do
		local blocks, order = {}, {}
		local tiled
		for _, layer in ipairs(w.layers or {}) do
			if layer.kind == "tiled" then
				tiled = layer
			end
		end
		if tiled and tiled.layout then
			for _, b in ipairs(tiled.blocks or {}) do
				blocks[b.block_id] = b
			end
			local function copy(node)
				if node.split then
					local s = node.split
					-- Leave out the name prompt, restoring the split it was added to.
					if prompt_block and s.after.block_id == prompt_block then
						return copy(s.before)
					end
					return {
						split = { direction = s.direction, ratio = s.ratio, before = copy(s.before), after = copy(s.after) },
					}
				end
				table.insert(order, node.block_id)
				return { block = pane(blocks[node.block_id]) }
			end
			local entry = { layout = copy(tiled.layout) }
			if w.label and not w.label:match("^Window %x+$") then
				entry.window_label = w.label
			end
			table.insert(windows, entry)
			if prompt_block and blocks[prompt_block] then
				w.focused_block_id = ctx.block_id
				w.zoomed_block_id = w.zoomed_block_id or zoomed_block
			end
			table.insert(old_ids, { window = w, blocks = order })
		end
	end

	local created = must(rex.call("session.create", { label = name, initial_windows = windows }))
	local session_id = created.session_id
	-- Focus and zoom calls are only accepted for the attached session.
	rex.call("session.attach", { session_id = session_id })

	-- Carry over each tab's focused and zoomed pane, then the active tab.
	local active_window
	for i, info in ipairs(old_ids) do
		local new_window = created.initial_windows[i]
		local new_id = {}
		for j, old in ipairs(info.blocks) do
			new_id[old] = (new_window.block_ids or {})[j]
		end
		local w = info.window
		if new_id[w.focused_block_id or ""] then
			rex.call("session.focus_block", { session_id = session_id, block_id = new_id[w.focused_block_id] })
		end
		if new_id[w.zoomed_block_id or ""] then
			rex.call("session.zoom_block", { session_id = session_id, block_id = new_id[w.zoomed_block_id], zoom = true })
		end
		if w.window_id == view.active_window_id then
			active_window = new_window.window_id
		end
	end
	if active_window then
		rex.call("session.focus_window", { session_id = session_id, window_id = active_window })
	end

	local switched = pcall(rex.client.queue, "session.select", { session_id = session_id })

	return {
		session_id = session_id,
		worktree = worktree,
		branch = name,
		switched = switched,
		task_agent = task_agent,
	}
end

rex.action({
	name = "worktree_mirror",
	title = "Mirror Session into New Worktree",
	description = "Create a git worktree on a new branch and open a copy of this session in it.",
	category = "Sessions",
	keywords = "git worktree branch clone duplicate session",
	args = { name = "string?", task = "string?", prompt_block = "string?", zoomed_block = "string?" },
	run = function(ctx, args)
		if args.name == nil or args.name == "" then
			return prompt_for_name(ctx)
		end
		return mirror(ctx, args)
	end,
})
