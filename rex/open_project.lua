-- open_project: pick a project in ~/code, then one of its git worktrees, then
-- where to open it: a floating pane over this tab, a new tab in this session,
-- or a new session shaped like the "dotfiles" session (three tabs:
-- shell/shell/lazygit split, opencode, nvim) with every pane started there.
--
--   rex do open_project
--   rex do open_project path=~/code/project where=session
--
-- Projects are the git repos under ~/code (up to three levels deep), plus any
-- top-level directory without a repo inside it. The worktree question is
-- skipped when a repo has only one. Typing a path that isn't in the list
-- opens that directory instead. The floating pane and the tab start a shell.

local P = require("projects")

local CODE_DIR = P.HOME .. "/code"

-- Prints "repo\t<path>" followed by `git worktree list --porcelain` for each
-- repo under $1, and "dir\t<path>" for each top-level directory with no repo.
-- Linked worktrees (.git is a file) are listed by their main repo instead.
local SCAN_SCRIPT = [[
PATH="/opt/homebrew/bin:$PATH"
scan() (
	if [ -d "$1/.git" ]; then
		printf 'repo\t%s\n' "$1"
		git -C "$1" worktree list --porcelain
		return 0
	fi
	[ -e "$1/.git" ] && return 0
	[ "$2" -lt 3 ] || return 1
	found=1
	for child in "$1"/*/; do
		[ -d "$child" ] && scan "${child%/}" $(($2 + 1)) && found=0
	done
	return $found
)
for dir in "$1"/*/; do
	[ -d "$dir" ] || continue
	scan "${dir%/}" 1 || printf 'dir\t%s\n' "${dir%/}"
done
]]

-- Returns the projects in the order to show them. Each has a path, a name
-- relative to ~/code and, for git repos, its worktrees (main one first).
local function scan_projects()
	local r, err = rex.exec({ "sh", "-c", SCAN_SCRIPT, "sh", CODE_DIR })
	if r == nil then
		error("Could not list projects: " .. tostring(err), 0)
	end
	local projects, project = {}, nil
	for line in r.stdout:gmatch("[^\n]+") do
		local kind, path = line:match("^(%a+)\t(.+)$")
		if kind then
			project = { path = path, name = path:sub(#CODE_DIR + 2), worktrees = {} }
			table.insert(projects, project)
		elseif project then
			P.read_worktree_line(project.worktrees, line)
		end
	end
	for _, p in ipairs(projects) do
		p.worktrees = P.usable_worktrees(p.worktrees)
	end
	table.sort(projects, function(a, b)
		return a.name < b.name
	end)
	return projects
end

local function choose_project(projects)
	local items = {}
	for _, p in ipairs(projects) do
		local main = p.worktrees[1]
		table.insert(items, {
			id = p.path,
			title = p.name,
			subtitle = main and P.worktree_title(main) or P.tilde(p.path),
			icon = main and "code" or "folder",
			detail = #p.worktrees > 1 and (#p.worktrees .. " worktrees") or nil,
		})
	end
	local answer = P.pick({
		title = "Open project",
		placeholder = "Filter projects, or type a path",
		items = items,
		allow_other = true,
	})
	if type(answer) == "table" then
		return { path = P.expand(answer.text), worktrees = {} }
	end
	for _, p in ipairs(projects) do
		if p.path == answer then
			return p
		end
	end
	return nil
end

-- Returns the worktree to open, or nil when the person cancelled.
local function choose_worktree(project)
	if #project.worktrees <= 1 then
		return { path = project.path }
	end
	local path = P.pick({
		title = "Open " .. P.basename(project.path) .. " worktree",
		placeholder = "Filter worktrees",
		items = P.worktree_items(project.worktrees, project.path),
	})
	for _, w in ipairs(project.worktrees) do
		if w.path == path then
			return w
		end
	end
	return nil
end

rex.action({
	name = "open_project",
	title = "Open project…",
	description = "Pick a project in ~/code and one of its git worktrees, and open it in a floating pane, a new tab, or a new session with the dotfiles layout (shells, lazygit, opencode, nvim).",
	category = "Global",
	keywords = "open project worktree branch new session tab float floating pane template layout directory path code",
	args = { path = "string?", where = "string?" },
	run = function(ctx, args)
		local path = args.path ~= "" and args.path or nil
		local where = args.where ~= "" and args.where or nil
		local label

		if path then
			path = P.expand(path)
		else
			local project = choose_project(scan_projects())
			if project == nil then
				return
			end
			local worktree = choose_worktree(project)
			if worktree == nil then
				return
			end
			path = worktree.path
			-- Linked worktrees are named after their branch, like worktree_mirror.
			if path ~= project.path then
				label = worktree.branch
			end
		end
		label = label or P.basename(path)

		if where == nil then
			where = P.choose_place(ctx, label)
			if where == nil then
				return
			end
		end
		return P.open_in(where, path, label)
	end,
})
