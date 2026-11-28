-- worktree_mirror: create a git worktree on a new branch from the current
-- pane's HEAD (or on the branch itself if it already exists locally), then
-- ask where to open it:
--
-- - float: a floating pane over the current tab that starts the same agent as
--   the calling pane in the worktree.
-- - tab: the same agent pane, in a new tab in this session.
-- - session: a new session that mirrors this session's tabs, splits and
--   running programs inside the worktree, and switch to it.
-- - none: only create the worktree and branch.
--
--   rex do worktree_mirror name=my-feature
--   rex do worktree_mirror --args '{"name":"my-feature","task":"Fix …"}'
--   rex do worktree_mirror --args '{"name":"my-feature","mode":"tab"}'
--
-- Without a name, the palette asks for one. Without a mode, the palette asks
-- where to open the worktree; cancelling either question creates nothing.
-- With a task, the agent in the worktree starts with it as its first prompt.
-- With resume (the calling claude or opencode conversation ID), that agent is
-- stopped and its conversation continues in the worktree instead, unless the
-- worktree isn't opened.

local P = require("projects")

local TERMINAL = "com.superlogical.terminal"
local SHELL_FLAVOR = "com.superlogical.terminal.shell"
local WORKTREES_DIR = ".claude/worktrees"
-- Typed into each mirrored pane inside the repo before its command runs.
local SETUP_COMMAND = "~/.config/rex/worktree-setup.sh"
-- How each agent CLI takes an initial prompt, keyed by process name.
local AGENT_TASK_FLAGS = { claude = "", codex = "", opencode = "--prompt " }
-- Builds of an agent that run under another process name.
local AGENT_ALIASES = { ["opencode-native"] = "opencode" }
-- How each agent CLI resumes a conversation by ID. OpenCode sessions also
-- remember their directory, so they're moved to the worktree first.
local AGENT_RESUME_FLAGS = { claude = "--resume ", opencode = "--session " }
-- The agent command is typed into the new pane, and the terminal driver
-- drops typed input past about 1 KiB per line (MAX_CANON on macOS). Longer
-- tasks are written to this file in the worktree, kept out of git through
-- info/exclude, and the agent is told to read it.
local MAX_INLINE_TASK = 500
local TASK_FILE = ".rex-task.md"

local function quote(s)
	return "'" .. (s:gsub("'", "'\\''")) .. "'"
end

-- Runs a shell command and returns its trimmed output and exit status.
-- The Rex app doesn't inherit the login shell's PATH, so Homebrew tools that
-- git shells out to (e.g. git-lfs) would otherwise be missing.
local function run(cmd)
	local r, err = rex.exec({ "sh", "-c", 'PATH="/opt/homebrew/bin:$PATH"; ' .. cmd .. " 2>&1" })
	if r == nil then
		return err, 1
	end
	return (r.stdout:gsub("%s+$", "")), r.code
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

-- session_id is needed for a block outside the session the action runs in.
local function process_of(block_id, session_id)
	local proc = rex.block.call(TERMINAL, "process", { block_id = block_id, session_id = session_id })
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

-- Which agent CLI a process is, and the command that starts it, or nil.
-- Claude Code's process is named after its version (e.g. 2.1.326), so argv0
-- is checked as well as the name.
local function agent_of(fg)
	for _, command in ipairs({ fg.name or "", (fg.argv0 or ""):match("[^/]*$") }) do
		local name = AGENT_ALIASES[command] or command
		if AGENT_TASK_FLAGS[name] then
			return name, command
		end
	end
	return nil
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

-- The agent to start in a worktree pane: the one in the source pane, or the
-- first agent running in this session when the source pane isn't one.
local function find_agent(source_process, view)
	local agent, command = agent_of(source_process)
	if agent then
		return agent, command
	end
	for _, w in ipairs(view.windows or {}) do
		for _, layer in ipairs(w.layers or {}) do
			for _, b in ipairs(layer.blocks or {}) do
				if b.creator_name == TERMINAL then
					agent, command = agent_of(process_of(b.block_id, view.session_id))
					if agent then
						return agent, command
					end
				end
			end
		end
	end
	return nil
end

-- Sessions this action attached to for a view, so it can detach from them.
local attached = {}

-- A session's view. Calls on a session this action isn't attached to are
-- refused, so it attaches first when needed.
local function view_of(session_id)
	local view = rex.call("session.view", { session_id = session_id })
	if view == nil then
		local r = must(rex.call("session.attach", { session_id = session_id }))
		attached[session_id] = true
		view = r.view
	end
	return must(view, "Could not read session " .. session_id)
end

-- `claude attach` takes the short ID that `claude agents` shows.
local function attach_id(session_id)
	return session_id:sub(1, 8)
end

-- A Claude Code background session runs in the Claude daemon, not in a pane.
-- Returns the Rex pane where the user follows it, as { session_id, block_id }:
-- a pane attached to it with `claude attach`, or else a `claude agents` pane.
local function viewer_of(claude_session)
	local short = attach_id(claude_session)
	local exact, fallback
	for _, s in ipairs(must(rex.call("session.list", {})).sessions or {}) do
		for _, w in ipairs(view_of(s.session_id).windows or {}) do
			for _, layer in ipairs(w.layers or {}) do
				for _, b in ipairs(layer.blocks or {}) do
					if not exact and b.creator_name == TERMINAL then
						local fg = process_of(b.block_id, s.session_id)
						local cmd = agent_of(fg) == "claude" and command_of(fg) or ""
						local target = cmd:match("%sattach%s+(%S+)")
						local here = { session_id = s.session_id, block_id = b.block_id }
						if target and (target == short or claude_session:sub(1, #target) == target) then
							exact = here
						elseif fallback == nil and cmd:match("%sagents") then
							fallback = here
						end
					end
				end
			end
		end
		if exact then
			break
		end
	end
	local viewer = exact or fallback
	for session_id in pairs(attached) do
		if not (viewer and viewer.session_id == session_id) then
			rex.call("session.detach", { session_id = session_id })
			attached[session_id] = nil
		end
	end
	return viewer
end

local function ask_name()
	local name, why = rex.ui.input({
		title = "New worktree",
		placeholder = "Branch name",
		confirm = "Create worktree",
	})
	if name == nil and why ~= "cancelled" then
		error("New worktree: no answer (" .. tostring(why) .. ")", 0)
	end
	name = name and name:match("^%s*(.-)%s*$")
	return name ~= "" and name or nil
end

-- Asks where to open the worktree. Each option says what will run there.
-- Returns nil when the person cancelled.
local function ask_mode(src, name)
	local runs
	if src.attach then
		runs = "shows this claude conversation"
	elseif src.resume then
		runs = "continues this " .. (agent_of(src.process) or "agent") .. " conversation"
	else
		local agent = find_agent(src.process, view_of(src.session_id))
		runs = agent and ("starts " .. agent) or "a shell"
	end
	local items = {}
	-- A background agent with no pane showing it has no tab to open in.
	if src.session_id then
		table.insert(items, { id = "float", title = "Floating pane", subtitle = "Over this tab, " .. runs, icon = "terminal" })
		table.insert(items, { id = "tab", title = "New tab", subtitle = "In this session, " .. runs, icon = "plus" })
	end
	table.insert(items, {
		id = "session",
		title = "New session",
		subtitle = src.block_id and "A copy of this session's tabs and programs" or ("One tab that " .. runs),
		icon = "code",
	})
	local stays
	if src.attach then
		stays = "Only create the worktree, the agent moves into it here"
	elseif src.resume then
		stays = "Only create the worktree, this conversation moves into it here"
	else
		stays = "Only create the worktree and branch"
	end
	table.insert(items, { id = "none", title = "Don't open", subtitle = stays, icon = "branch" })
	return P.pick({ title = "Open " .. name .. " in", items = items })
end

-- Creates the worktree and branch, copies env files, and writes a long task
-- to the task file. Returns what both ways of opening the worktree need.
local function create_worktree(src, args)
	local name = args.name
	local source_cwd = src.process.cwd
	local source_root = must(git(source_cwd, "rev-parse --show-toplevel"))

	local common_dir = must(git(source_root, "rev-parse --path-format=absolute --git-common-dir"))
	local main_root = common_dir:gsub("/%.git/?$", "")
	local worktree = main_root .. "/" .. WORKTREES_DIR .. "/" .. name

	must(git(source_root, "check-ref-format --branch " .. quote(name)))
	local branch_exists = git(source_root, "show-ref --verify --quiet " .. quote("refs/heads/" .. name)) ~= nil
	if branch_exists then
		must(git(source_root, "worktree add " .. quote(worktree) .. " " .. quote(name)))
	else
		must(git(source_root, "worktree add -b " .. quote(name) .. " " .. quote(worktree)))
	end

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

	local task = args.task ~= "" and args.task or nil
	if task and #task > MAX_INLINE_TASK then
		local path = worktree .. "/" .. TASK_FILE
		local exclude = must(git(worktree, "rev-parse --path-format=absolute --git-path info/exclude"))
		local r, err = rex.exec({
			"sh",
			"-c",
			'printf "%s\\n" "$1" > "$2" && mkdir -p "$(dirname "$3")" && '
				.. '{ grep -qxF "/$4" "$3" 2>/dev/null || printf "/%s\\n" "$4" >> "$3"; }',
			"sh",
			task,
			path,
			exclude,
			TASK_FILE,
		})
		if r == nil or r.code ~= 0 then
			error("Could not write the task file: " .. (r and ((r.stdout or "") .. (r.stderr or "")) or tostring(err)), 0)
		end
		task = "Read the task brief in " .. path .. " and carry it out."
	end

	return {
		name = name,
		source_block = src.block_id,
		source_process = src.process,
		resume = src.resume,
		attach = src.attach,
		worktree = worktree,
		branch_exists = branch_exists,
		task = task,
		remap = remap,
	}
end

-- The window holding a block, from a session view.
local function window_of(view, block_id)
	for _, w in ipairs(view.windows or {}) do
		for _, layer in ipairs(w.layers or {}) do
			for _, b in ipairs(layer.blocks or {}) do
				if b.block_id == block_id then
					return w
				end
			end
		end
	end
	return nil
end

-- Stops the agent that asked for the worktree and resumes its conversation in
-- the worktree, so the context carries over. Returns the steps to run before
-- the setup command and the command that starts the agent. The old agent is
-- stopped from the new pane, after this action has returned its result.
local function resume_launch(wt, cwd)
	local agent, command = agent_of(wt.source_process)
	local pid = must(wt.source_process.pid, "Could not find the agent's process to stop")
	local pre = { "{ kill " .. pid .. " 2>/dev/null; while kill -0 " .. pid .. " 2>/dev/null; do sleep 0.2; done; }" }
	if agent == "opencode" then
		local body = '{"directory":"' .. cwd:gsub('[\\"]', "\\%0") .. '"}'
		table.insert(pre, command .. " api session.move --param sessionID=" .. quote(wt.resume) .. " -d " .. quote(body) .. " >/dev/null")
	end
	local note = "You were moved into the git worktree "
		.. cwd
		.. " (branch "
		.. wt.name
		.. ") in a new Rex pane, and your old process was stopped. worktree_mirror already succeeded: don't run it again. Work here from now on. "
		.. (wt.task and ("Next: " .. wt.task) or "Continue where you left off.")
	return pre, command .. " " .. AGENT_RESUME_FLAGS[agent] .. quote(wt.resume) .. " " .. AGENT_TASK_FLAGS[agent] .. quote(note)
end

-- The steps typed into a new pane in the worktree: setup, then the agent.
-- Returns them with the agent CLI that will run there, if any.
local function pane_steps(wt, cwd, in_repo, agent, command)
	local steps, launch = {}, nil
	if wt.attach then
		launch, agent = "claude attach " .. quote(attach_id(wt.attach)), "claude"
	elseif wt.resume then
		steps, launch = resume_launch(wt, cwd)
	elseif agent then
		launch = command .. (wt.task and (" " .. AGENT_TASK_FLAGS[agent] .. quote(wt.task)) or "")
	end
	if in_repo then
		table.insert(steps, SETUP_COMMAND)
	end
	if launch then
		table.insert(steps, launch)
	end
	return steps, agent
end

-- float or tab: start one agent in the worktree, in a focused floating pane
-- over the current tab or in a new tab. It's the agent that asked for the
-- worktree, or the first agent running in this session when the request came
-- from somewhere else. With resume, it's the asking agent's own conversation,
-- moved over; with attach, a view of the background session.
local function open_pane(src, wt, mode)
	local view = view_of(src.session_id)
	local agent, command = find_agent(wt.source_process, view)

	local cwd, in_repo = wt.remap(wt.source_process.cwd)
	local steps
	steps, agent = pane_steps(wt, cwd, in_repo, agent, command)
	local options = { cwd = cwd }
	if #steps > 0 then
		options.initial_input = table.concat(steps, " && ") .. "\n"
	end
	local layout = { block = { flavor = SHELL_FLAVOR, label = wt.name, options = options } }

	local result = {
		mode = mode,
		session_id = src.session_id,
		worktree = wt.worktree,
		branch = wt.name,
		existing_branch = wt.branch_exists,
		task_agent = (wt.task and agent) or nil,
		resumed_agent = (wt.resume and agent) or nil,
		attached = wt.attach and true or nil,
	}
	if mode == "tab" then
		local created = must(rex.call("session.new_window", {
			session_id = src.session_id,
			window_label = wt.name,
			layout = layout,
		}))
		result.window_id = created.window_id
		result.block_id = (created.block_ids or {})[1]
	else
		local window = window_of(view, wt.source_block)
		local created = must(rex.call("session.new_layer", {
			session_id = src.session_id,
			window_id = window and window.window_id or nil,
			bounds = { 0.05, 0.05, 0.9, 0.9 },
			focus = true,
			layout = layout,
		}))
		result.layer_id = created.layer_id
		result.block_id = (created.block_ids or {})[1]
	end
	return result
end

-- A new session that mirrors this one inside the worktree. For a background
-- agent no pane shows, it's a session with one tab showing the agent.
local function open_session(src, wt)
	local name = wt.name
	local source_block = wt.source_block
	local source_process = wt.source_process
	local worktree = wt.worktree
	local branch_exists = wt.branch_exists
	local task = wt.task
	local remap = wt.remap

	-- The task goes to the copy of the agent that asked for the worktree, so a
	-- Claude Code request continues in Claude Code and an OpenCode one in
	-- OpenCode. Requests from elsewhere go to the first agent pane.
	local task_agent
	local source_is_agent = agent_of(source_process) ~= nil
	local function with_task(block, fg, cmd)
		local agent = agent_of(fg)
		if not (task and cmd and agent) or task_agent then
			return cmd
		end
		if source_is_agent and block.block_id ~= source_block then
			return cmd
		end
		task_agent = agent
		return cmd .. " " .. AGENT_TASK_FLAGS[agent] .. quote(task)
	end

	local function pane(block)
		if block.creator_name ~= TERMINAL then
			return { flavor = SHELL_FLAVOR, options = { cwd = worktree, initial_input = SETUP_COMMAND .. "\n" } }
		end
		local fg = process_of(block.block_id, src.session_id)
		local cwd, in_repo = remap(fg.cwd)
		local steps
		if block.block_id == source_block and (wt.resume or wt.attach) then
			if wt.attach then
				cwd, in_repo = remap(source_process.cwd)
			end
			steps = pane_steps(wt, cwd, in_repo)
			task_agent = (task and wt.resume) and agent_of(fg) or task_agent
		else
			local launch = with_task(block, fg, command_of(fg))
			steps = {}
			if in_repo then
				table.insert(steps, SETUP_COMMAND)
			end
			if launch then
				table.insert(steps, launch)
			end
		end
		local options = { cwd = cwd }
		if #steps > 0 then
			options.initial_input = table.concat(steps, " && ") .. "\n"
		end
		return { flavor = block.flavor, options = options }
	end

	local view = src.session_id and view_of(src.session_id) or { windows = {} }
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
			table.insert(old_ids, { window = w, blocks = order })
		end
	end
	if #windows == 0 then
		local cwd, in_repo = remap(source_process.cwd)
		local steps = pane_steps(wt, cwd, in_repo)
		local options = { cwd = cwd }
		if #steps > 0 then
			options.initial_input = table.concat(steps, " && ") .. "\n"
		end
		windows = { { window_label = name, layout = { block = { flavor = SHELL_FLAVOR, options = options } } } }
	end

	local created = must(rex.call("session.create", { label = "\xee\x9c\xa5 " .. name, initial_windows = windows }))
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
		mode = "session",
		session_id = session_id,
		worktree = worktree,
		branch = name,
		existing_branch = branch_exists,
		switched = switched,
		task_agent = task_agent,
		resumed_agent = wt.resume and agent_of(source_process) or nil,
		attached = wt.attach and true or nil,
	}
end

rex.action({
	name = "worktree_mirror",
	title = "New worktree…",
	description = "Create a git worktree on a new or existing branch, then choose where to open it: a floating agent pane, a new tab, a copy of this session, or nowhere. With resume, the calling agent's conversation moves into the worktree. A Claude Code background session passes attach and cwd instead, and the worktree opens showing it.",
	category = "Sessions",
	keywords = "git worktree branch clone duplicate mirror session tab float floating pane",
	args = {
		name = "string?",
		task = "string?",
		mode = "string?",
		resume = "string?",
		attach = "string?",
		cwd = "string?",
	},
	run = function(ctx, args)
		local resume = args.resume ~= "" and args.resume or nil
		local attach = args.attach ~= "" and args.attach or nil
		local src
		if attach then
			-- A Claude Code background session: no pane of its own, so it names
			-- its directory, and the worktree opens where the user follows it.
			if resume then
				error("Pass either resume or attach, not both", 0)
			end
			local cwd = must(args.cwd ~= "" and args.cwd or nil, "attach needs cwd, the agent's working directory")
			local viewer = viewer_of(attach) or {}
			src = { session_id = viewer.session_id, block_id = viewer.block_id, process = { cwd = cwd }, attach = attach }
		else
			local block_id = must(ctx.block_id, "worktree_mirror needs a pane to start from")
			src = { session_id = ctx.session_id, block_id = block_id, process = process_of(block_id), resume = resume }
			must(src.process.cwd, "Could not read the pane's working directory")
			if resume then
				local agent = agent_of(src.process)
				if not (agent and AGENT_RESUME_FLAGS[agent]) then
					error("resume only works when called from a claude or opencode pane", 0)
				end
			end
		end
		must(git(src.process.cwd, "rev-parse --show-toplevel"))

		local name = args.name ~= "" and args.name or nil
		if name == nil then
			name = ask_name()
			if name == nil then
				return { cancelled = true }
			end
		end
		must(git(src.process.cwd, "check-ref-format --branch " .. quote(name)))

		local mode = args.mode ~= "" and args.mode or nil
		if mode == nil then
			mode = ask_mode(src, name)
			if mode == nil then
				return { cancelled = true }
			end
		end
		if mode ~= "float" and mode ~= "tab" and mode ~= "session" and mode ~= "none" then
			error("mode must be float, tab, session or none, not " .. mode, 0)
		end
		if (mode == "float" or mode == "tab") and src.session_id == nil then
			error("No Rex pane shows this agent, so there's no tab to open " .. mode .. " in", 0)
		end

		-- A background agent continues on its own, so a task isn't passed on.
		local wt = create_worktree(src, { name = name, task = (not attach) and args.task or nil })
		if mode == "none" then
			return {
				mode = "none",
				session_id = src.session_id,
				worktree = wt.worktree,
				branch = wt.name,
				existing_branch = wt.branch_exists,
			}
		end
		if mode == "session" then
			return open_session(src, wt)
		end
		return open_pane(src, wt, mode)
	end,
})
