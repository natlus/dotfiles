return {
	"echasnovski/mini.nvim",
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

		statusline.setup({
			use_icons = true,
			content = {
				active = function()
					local mode, mode_hl = statusline.section_mode({ trunc_width = 120 })
					local git = statusline.section_git({ trunc_width = 40 })
					local git_status = vim.b.gitsigns_status_dict or {}
					local git_diff = statusline.combine_groups({
						{ strings = { git_status.added and git_status.added > 0 and ("+" .. git_status.added) or "" } },
						{
							strings = {
								git_status.changed and git_status.changed > 0 and ("~" .. git_status.changed) or "",
							},
						},
						{
							strings = {
								git_status.removed and git_status.removed > 0 and ("-" .. git_status.removed) or "",
							},
						},
					})
					local diagnostics = statusline.section_diagnostics({ trunc_width = 75 })
					local clients = vim.lsp.get_clients({ bufnr = 0 })
					local hidden_lsp_clients = { oxfmt = true, stylua = true }
					local client_names = vim.tbl_filter(
						function(name)
							return not hidden_lsp_clients[name]
						end,
						vim.tbl_map(function(client)
							return client.name
						end, clients)
					)
					local lsp = table.concat(client_names, ", ")
					local filename = statusline.section_filename({ trunc_width = 140 })
					local location = statusline.section_location({ trunc_width = 75 })
					local search = statusline.section_searchcount({ trunc_width = 75 })

					return statusline.combine_groups({
						{ hl = mode_hl, strings = { mode } },
						{ hl = "MiniStatuslineDevinfo", strings = { git, git_diff, diagnostics } },
						"%<",
						{ hl = "MiniStatuslineFilename", strings = { filename } },
						"%=",
						{ hl = "MiniStatuslineFileinfo", strings = { lsp } },
						{ hl = mode_hl, strings = { search, location } },
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
