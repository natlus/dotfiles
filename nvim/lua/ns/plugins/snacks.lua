return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	---@type snacks.Config
	opts = {
		bigfile = { enabled = true },
		dashboard = { enabled = true },
		explorer = { enabled = true },
		indent = { enabled = true },
		input = { enabled = true },
		picker = {
			enabled = true,
			actions = {
				---@param picker snacks.Picker
				opencode_send = function(picker)
					local items = vim.tbl_map(function(item) ---@param item snacks.picker.Item
						return item.file
								and require("opencode").format({ path = item.file, from = item.pos, to = item.end_pos })
							or item.text
					end, picker:selected({ fallback = true }))

					require("opencode").prompt(table.concat(items, ", ") .. " ")
				end,
			},
			win = {
				input = {
					keys = {
						["<a-a>"] = { "opencode_send", mode = { "n", "i" } },
					},
				},
			},

			matcher = {
				history_bonus = false,
				frecency = true,
			},
			formatters = {
				file = {
					filename_first = true,
				},
			},
			-- layout = {
			-- 	reverse = true,
			-- 	layout = {
			-- 		box = "horizontal",
			-- 		backdrop = false,
			-- 		width = 0.8,
			-- 		height = 0.9,
			-- 		border = "none",
			-- 		{
			-- 			box = "vertical",
			-- 			{ win = "list", title = " Results ", title_pos = "center", border = true },
			-- 			{
			-- 				win = "input",
			-- 				height = 1,
			-- 				border = true,
			-- 				title = "{title} {live} {flags}",
			-- 				title_pos = "center",
			-- 			},
			-- 		},
			-- 		{
			-- 			win = "preview",
			-- 			title = "{preview:Preview}",
			-- 			width = 0.45,
			-- 			border = true,
			-- 			title_pos = "center",
			-- 		},
			-- 	},
			-- },
		},
		notifier = { enabled = true },
		quickfile = { enabled = true },
		scope = { enabled = true },
		scroll = { enabled = true },
		statuscolumn = { enabled = true },
		words = { enabled = true },
	},
	keys = {
		{
			"<leader>sf",
			function()
				Snacks.picker.files()
			end,
			desc = "Find Files",
		},
		{
			"<leader>f.",
			function()
				Snacks.picker.recent()
			end,
			desc = "Recent",
		},
		{
			"gr",
			function()
				Snacks.picker.lsp_references()
			end,
			nowait = true,
			desc = "References",
		},
		{
			"gd",
			function()
				Snacks.picker.lsp_definitions()
			end,
			desc = "Goto Definition",
		},
		{
			"gI",
			function()
				Snacks.picker.lsp_implementations()
			end,
			desc = "Goto Implementation",
		},
		{
			"<leader>ss",
			function()
				Snacks.picker.lsp_symbols()
			end,
			desc = "LSP Symbols",
		},
		{
			"<leader>sS",
			function()
				Snacks.picker.lsp_workspace_symbols()
			end,
			desc = "LSP Workspace Symbols",
		},
		{
			"<leader>se",
			function()
				Snacks.explorer()
			end,
			desc = "File Explorer",
		},
		{
			"<leader>/",
			function()
				Snacks.picker.grep()
			end,
			desc = "Grep",
		},
	},
}
