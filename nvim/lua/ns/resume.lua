-- Program Resume Protocol (OSC 7577): keeps a session file for this Neovim and
-- tells the terminal to run `nvim -S <file>` to bring it back, so Rex restores
-- it after a server restart. Rex trusts this with its `resume.trust.nvim` rule.

local token = vim.env.OSC7577_TOKEN
-- Children (terminals, LSPs, lazygit) must not report in Neovim's place.
vim.env.OSC7577_TOKEN = nil
if not token or token == "" then
	return
end

local dir = vim.fn.stdpath("state") .. "/sessions"
local max_age = 30 * 24 * 60 * 60

-- A resumed Neovim keeps the file it was started with.
local function resumed_file()
	local argv = vim.v.argv
	for i = 1, #argv - 1 do
		if argv[i] == "-S" then
			local path = vim.fn.fnamemodify(argv[i + 1], ":p")
			if vim.startswith(path, dir .. "/") then
				return path
			end
		end
	end
end

local file = resumed_file() or ("%s/%s-%d.vim"):format(dir, os.date("%Y%m%d-%H%M%S"), vim.fn.getpid())

local function send(fields)
	-- This process is Neovim's server. The terminal runs its parent, the TUI.
	local body = ("pid=%d:time=%d:%s"):format(vim.uv.os_getppid(), os.time(), fields)
	local mac = vim.fn.sha256(body .. ":" .. token)
	pcall(vim.api.nvim_ui_send, "\27]7577;" .. body .. ":mac=" .. mac .. "\27\\")
end

local function report()
	local argv = { "nvim", "-S", file }
	for i, arg in ipairs(argv) do
		argv[i] = vim.base64.encode(arg)
	end
	send("argv=" .. table.concat(argv, ","))
end

local function save()
	-- Don't take over v:this_session, auto-session uses it.
	local previous = vim.v.this_session
	local ok = pcall(vim.cmd, "silent mksession! " .. vim.fn.fnameescape(file))
	vim.v.this_session = previous
	return ok
end

local function purge()
	local now = os.time()
	for name, kind in vim.fs.dir(dir) do
		local path = dir .. "/" .. name
		local stat = kind == "file" and path ~= file and vim.uv.fs_stat(path)
		if stat and now - stat.mtime.sec > max_age then
			os.remove(path)
		end
	end
end

local timer = assert(vim.uv.new_timer())
local group = vim.api.nvim_create_augroup("ns_resume", {})

vim.api.nvim_create_autocmd("VimEnter", {
	group = group,
	callback = function()
		if #vim.api.nvim_list_uis() == 0 then
			return
		end
		vim.fn.mkdir(dir, "p", tonumber("700", 8))
		vim.schedule(function()
			if save() then
				report()
			end
			purge()
		end)

		vim.api.nvim_create_autocmd({ "BufEnter", "WinClosed", "TabClosed", "DirChanged", "FocusLost" }, {
			group = group,
			callback = function()
				timer:start(1000, 0, vim.schedule_wrap(save))
			end,
		})
		vim.api.nvim_create_autocmd("VimResume", { group = group, callback = report })
		vim.api.nvim_create_autocmd("VimLeavePre", {
			group = group,
			callback = function()
				timer:stop()
				-- 0 means the user quit. A hangup, such as Rex restarting, exits with 1.
				if vim.v.exiting == 0 then
					send("clear=1")
					os.remove(file)
				else
					save()
				end
			end,
		})
	end,
})
