return {
	"nvim-mini/mini.nvim",
	config = function()
		require("mini.ai").setup({ n_lines = 500 })
		require("mini.surround").setup({
			mappings = {
				add = "sa",
				delete = "ds",
				find = "fs",
				replace = "rs",
			},
		})
		require("mini.move").setup({
			mappings = {
				down = "J",
				up = "K",
			},
		})
		require("mini.pairs").setup()
		require("mini.cmdline").setup()

		local statusline = require("mini.statusline")
		vim.api.nvim_set_hl(0, "NsStatuslineBasename", { fg = "#ffffff" })
		local mode_names = {
			n = "normal",
			no = "normal",
			nov = "normal",
			noV = "normal",
			["no\22"] = "normal",
			niI = "normal",
			niR = "normal",
			niV = "normal",
			nt = "normal",
			v = "visual",
			vs = "visual",
			V = "visual-line",
			Vs = "visual-line",
			["\22"] = "visual-block",
			["\22s"] = "visual-block",
			s = "select",
			S = "select-line",
			["\19"] = "select-block",
			i = "insert",
			ic = "insert",
			ix = "insert",
			R = "replace",
			Rc = "replace",
			Rx = "replace",
			Rv = "virtual-replace",
			Rvc = "virtual-replace",
			Rvx = "virtual-replace",
			c = "command",
			cv = "vim-ex",
			ce = "ex",
			r = "prompt",
			rm = "more",
			["r?"] = "confirm",
			["!"] = "shell",
			t = "terminal",
		}

		statusline.setup({
			use_icons = true,
			content = {
				active = function()
					local mode_name = mode_names[vim.fn.mode()]
					local mode = "--" .. mode_name:upper() .. "--"
					local git = vim.b.gitsigns_head or ""
					local git_status = vim.b.gitsigns_status_dict or {}
					local deleted = git_status.removed or 0
					local added = git_status.added or 0
					local git_deleted = deleted > 0 and ("%#GitSignsDelete#-" .. deleted) or ""
					local git_added = added > 0 and ("%#GitSignsAdd#+" .. added) or ""
					local filename = vim.fn.expand("%:.")
					local path = filename:match("^(.*/)") or ""
					local basename = vim.fn.fnamemodify(filename, ":t")
					local errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
					local warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
					local diagnostics = statusline.combine_groups({
						{ strings = { errors > 0 and ("%#GitSignsDelete#e:" .. errors) or "" } },
						{ strings = { warnings > 0 and ("%#GitSignsChange#w:" .. warnings) or "" } },
					})
					local filetype = vim.bo.filetype
					local location = statusline.section_location()

					return statusline.combine_groups({
						{ strings = { mode } },
						{ strings = { git, git_deleted .. git_added .. "%#MiniStatuslineFilename#" } },
						"%<",
						{ hl = "MiniStatuslineFilename", strings = { path .. "%#NsStatuslineBasename#" .. basename } },
						{ strings = { diagnostics .. "%#MiniStatuslineFilename#" } },
						"%=",
						{ hl = "MiniStatuslineFileinfo", strings = { filetype } },
						{ strings = { location } },
					})
				end,
			},
		})

		---@diagnostic disable-next-line: duplicate-set-field
		statusline.section_location = function()
			return "%2l:%-2v"
		end
	end,
}
