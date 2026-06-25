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
			n = "NOR",
			no = "NOR",
			nov = "NOR",
			noV = "NOR",
			["no\22"] = "NOR",
			niI = "NOR",
			niR = "NOR",
			niV = "NOR",
			nt = "NOR",
			v = "VIS",
			vs = "VIS",
			V = "VIS",
			Vs = "VIS",
			["\22"] = "VIS",
			["\22s"] = "VIS",
			s = "SEL",
			S = "SEL",
			["\19"] = "SEL",
			i = "INS",
			ic = "INS",
			ix = "INS",
			R = "REP",
			Rc = "REP",
			Rx = "REP",
			Rv = "VRP",
			Rvc = "VRP",
			Rvx = "VRP",
			c = "CMD",
			cv = "EX",
			ce = "EX",
			r = "PRM",
			rm = "MOR",
			["r?"] = "CNF",
			["!"] = "SHL",
			t = "TER",
		}

		statusline.setup({
			use_icons = true,
			content = {
				active = function()
					local mode_name = mode_names[vim.fn.mode()] or "UNK"
					local mode = mode_name
					local git = vim.b.gitsigns_head or ""
					local git_status = vim.b.gitsigns_status_dict or {}
					local git_modified = (git_status.added or 0) + (git_status.changed or 0) + (git_status.removed or 0)
						> 0
					local git_info = git .. (git_modified and "[+]" or "")
					local filename = vim.fn.expand("%:.")
					local path = filename:match("^(.*/)") or ""
					local basename = vim.fn.fnamemodify(filename, ":t")
					local errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
					local warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
					local diagnostics = statusline.combine_groups({
						{ strings = { errors > 0 and ("%#GitSignsDelete#e:" .. errors) or "" } },
						{ strings = { warnings > 0 and ("%#GitSignsChange#w:" .. warnings) or "" } },
					})
					local filetype = vim.bo.filetype == "typescriptreact" and "tsx" or vim.bo.filetype
					local location = statusline.section_location()

					return statusline.combine_groups({
						{ strings = { mode } },
						"%<",
						{ hl = "MiniStatuslineFilename", strings = { path .. "%#NsStatuslineBasename#" .. basename } },
						{ strings = { git_info .. "%#MiniStatuslineFilename#" } },
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
