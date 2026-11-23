-- Helpers shared by the open_project and open_worktree actions.

local M = {}

M.SHELL_FLAVOR = "com.superlogical.terminal.shell"
M.TERMINAL = "com.superlogical.terminal"
M.HOME = os.getenv("HOME") or ""

function M.expand(path)
	if path == "~" or path:sub(1, 2) == "~/" then
		path = M.HOME .. path:sub(2)
	end
	return (path:gsub("/+$", ""))
end

function M.tilde(path)
	if path:sub(1, #M.HOME + 1) == M.HOME .. "/" then
		return "~" .. path:sub(#M.HOME + 1)
	end
	return path
end

function M.basename(path)
	return path:match("([^/]+)$") or path
end

function M.must(value, err)
	if value == nil then
		error(err, 0)
	end
	return value
end

-- Each pane types its command into a shell, so quitting the program leaves a
-- shell behind. A nil command is a plain shell.
function M.pane(path, command, label)
	local options = { cwd = path }
	if command then
		options.initial_input = command .. "\n"
	end
	return rex.layout.block({ flavor = M.SHELL_FLAVOR, label = label, options = options })
end

-- The "dotfiles" session layout: shell/shell/lazygit split, opencode, nvim.
function M.template(path)
	return {
		{
			layout = rex.layout.horizontal(
				0.4,
				rex.layout.vertical(0.5, M.pane(path), M.pane(path)),
				M.pane(path, "lazygit")
			),
		},
		{ layout = M.pane(path, "opencode") },
		{ layout = M.pane(path, "nvim") },
	}
end

function M.check_dir(path)
	if path:sub(1, 1) ~= "/" then
		error("Path must be absolute or start with ~: " .. path, 0)
	end
	local result = rex.exec({ "test", "-d", path })
	if result == nil or result.code ~= 0 then
		error("Not a directory: " .. path, 0)
	end
end

-- Opens path in a new session with the template layout and switches to it.
function M.open_session(path, label)
	M.check_dir(path)
	local created = M.must(rex.call("session.create", {
		label = label or M.basename(path),
		initial_windows = M.template(path),
	}))
	local switched = pcall(rex.client.queue, "session.select", { session_id = created.session_id })
	return { where = "session", session_id = created.session_id, path = path, switched = switched }
end

-- Opens path in a focused floating pane over the current tab, running a shell.
function M.open_float(path, label)
	M.check_dir(path)
	local created = M.must(rex.session.new_layer({
		bounds = { 0.05, 0.05, 0.9, 0.9 },
		focus = true,
		layout = M.pane(path, nil, label),
	}))
	return { where = "float", layer_id = created.layer_id, block_id = (created.block_ids or {})[1], path = path }
end

-- Opens path in a new tab in the current session, running a shell.
function M.open_tab(path, label)
	M.check_dir(path)
	local created = M.must(rex.session.new_window({
		window_label = label,
		layout = M.pane(path),
	}))
	return { where = "tab", window_id = created.window_id, block_id = (created.block_ids or {})[1], path = path }
end

function M.open_in(where, path, label)
	if where == "float" then
		return M.open_float(path, label)
	elseif where == "tab" then
		return M.open_tab(path, label)
	elseif where == "session" then
		return M.open_session(path, label)
	end
	error("where must be float, tab or session, not " .. tostring(where), 0)
end

local PLACES = {
	{ id = "float", title = "Floating pane", subtitle = "Over this tab", icon = "terminal" },
	{ id = "tab", title = "New tab", subtitle = "In this session", icon = "plus" },
	{ id = "session", title = "New session", subtitle = "Shells, lazygit, opencode and nvim", icon = "code" },
}

-- Asks where to open label: a floating pane, a tab or a session. Without a
-- current session only a new session makes sense, so nothing is asked.
-- Returns nil when the person cancelled.
function M.choose_place(ctx, label)
	if ctx.session_id == nil then
		return "session"
	end
	return M.pick({ title = "Open " .. label .. " in", items = PLACES })
end

-- Asks with rex.ui.pick and returns the answer, or nil when the person
-- cancelled. Any other reason for not getting an answer is an error.
function M.pick(spec)
	if rex.ui == nil then
		error(spec.title .. " needs rex.ui, which this Rex server is too old for. Restart the Rex server to finish updating.", 0)
	end
	local answer, why, detail = rex.ui.pick(spec)
	if answer == nil and why ~= "cancelled" then
		error(spec.title .. ": no answer (" .. tostring(why) .. (detail and (": " .. detail) or "") .. ")", 0)
	end
	return answer
end

-- Feeds one line of `git worktree list --porcelain` into list. Returns false
-- for lines that aren't part of that output.
function M.read_worktree_line(list, line)
	local current = list[#list]
	if line:match("^worktree ") then
		table.insert(list, { path = line:sub(10) })
	elseif current == nil then
		return false
	elseif line:match("^branch ") then
		current.branch = (line:sub(8):gsub("^refs/heads/", ""))
	elseif line:match("^HEAD ") then
		current.head = line:sub(6, 12)
	elseif line == "bare" or line:match("^prunable") then
		current.skip = true
	end
	return true
end

-- Drops bare and prunable worktrees, keeping the main one first.
function M.usable_worktrees(list)
	local kept = {}
	for _, w in ipairs(list) do
		if not w.skip then
			table.insert(kept, w)
		end
	end
	return kept
end

function M.worktree_title(w)
	return w.branch or ("detached at " .. (w.head or "?"))
end

-- rex.ui.pick items for a repo's worktrees, the main one (root) first.
-- current, when given, is the path of the worktree to mark as current.
function M.worktree_items(worktrees, root, current)
	local items = {}
	for i, w in ipairs(worktrees) do
		local inside = w.path:sub(1, #root + 1) == root .. "/"
		local tags = {}
		if i == 1 then
			table.insert(tags, "main")
		end
		if w.path == current then
			table.insert(tags, "current")
		end
		table.insert(items, {
			id = w.path,
			title = M.worktree_title(w),
			subtitle = inside and w.path:sub(#root + 2) or M.tilde(w.path),
			icon = "branch",
			detail = #tags > 0 and table.concat(tags, ", ") or nil,
		})
	end
	return items
end

return M
