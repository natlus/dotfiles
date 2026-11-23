-- open_worktree: pick one of the current repo's git worktrees, then where to
-- open it: a floating pane over this tab, a new tab in this session, or a new
-- session with the "dotfiles" layout (shells, lazygit, opencode, nvim).
--
--   rex do open_worktree
--   rex do open_worktree path=~/code/project/.claude/worktrees/x where=tab
--
-- The repo is the one the focused pane's working directory is in. The
-- floating pane and the tab start a shell in the worktree.

local P = require("projects")

-- Prints the pane's worktree root, then `git worktree list --porcelain`.
local LIST_SCRIPT = [[
PATH="/opt/homebrew/bin:$PATH"
git -C "$1" rev-parse --show-toplevel && git -C "$1" worktree list --porcelain
]]

local function cwd_of(block_id)
	local proc = rex.block.call(P.TERMINAL, "process", { block_id = block_id })
	local fg = proc and proc.foreground or {}
	if fg.cwd then
		return fg.cwd
	end
	-- Some programs (e.g. top) hide their cwd; fall back to the shell's.
	for _, ancestor in ipairs(proc and proc.ancestors or {}) do
		if ancestor.cwd then
			return ancestor.cwd
		end
	end
	return nil
end

-- Returns the repo's usable worktrees (main one first) and the path of the
-- worktree the focused pane is in.
local function list_worktrees(ctx)
	local block_id = P.must(ctx.block_id, "Open worktree needs a focused pane in a git repo")
	local cwd = P.must(cwd_of(block_id), "Could not read the pane's working directory")
	local r, err = rex.exec({ "sh", "-c", LIST_SCRIPT, "sh", cwd })
	if r == nil then
		error("Could not list worktrees: " .. tostring(err), 0)
	end
	if r.code ~= 0 then
		error("Not in a git repo: " .. P.tilde(cwd), 0)
	end
	local current = r.stdout:match("^[^\n]+")
	local worktrees = {}
	for line in r.stdout:gmatch("[^\n]+") do
		P.read_worktree_line(worktrees, line)
	end
	return P.usable_worktrees(worktrees), current
end

rex.action({
	name = "open_worktree",
	title = "Open worktree…",
	description = "Pick one of the current repo's git worktrees and open it in a floating pane, a new tab, or a new session with the dotfiles layout.",
	category = "Sessions",
	keywords = "open git worktree branch float floating pane tab session",
	args = { path = "string?", where = "string?" },
	run = function(ctx, args)
		local path = args.path ~= "" and args.path or nil
		local where = args.where ~= "" and args.where or nil
		local label

		if path then
			path = P.expand(path)
			label = P.basename(path)
		else
			local worktrees, current = list_worktrees(ctx)
			path = P.pick({
				title = "Open worktree",
				placeholder = "Filter " .. P.basename(worktrees[1].path) .. " worktrees",
				items = P.worktree_items(worktrees, worktrees[1].path, current),
			})
			if path == nil then
				return
			end
			for _, w in ipairs(worktrees) do
				if w.path == path then
					label = P.worktree_title(w)
				end
			end
		end

		if where == nil then
			where = P.choose_place(ctx, label)
			if where == nil then
				return
			end
		end
		return P.open_in(where, path, label)
	end,
})
