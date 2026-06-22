return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	---@type snacks.Config
	opts = {
		terminal = {
			enabled = true,
			win = {
				position = "float",
				width = 0.75,
				height = 0.55,
				border = "rounded",
				title = " Terminal ",
				title_pos = "center",
				backdrop = 60,
				wo = {
					statusline = "%#SnacksTitle# %{mode() ==# 't' ? 'INSERT' : 'NORMAL'} %*",
				},
				on_win = function(win)
					win:add_padding()
					Snacks.util.wo(win.win, win.opts.wo)
				end,
			},
		},
		bigfile = { enabled = false },
		dashboard = { enabled = false },
		explorer = { enabled = false },
		indent = { enabled = true },
		input = { enabled = true },
		picker = {
			enabled = true,
			sources = {
				files = {
					hidden = true,
					ignored = true,
					exclude = { ".next", ".next-dev", "node_modules" },
				},
			},
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
		},
		notifier = { enabled = false },
		quickfile = { enabled = true },
		scope = { enabled = true },
		scroll = { enabled = true },
		statuscolumn = { enabled = false },
		words = { enabled = true },
	},
	keys = {
		{
			"<leader>ft",
			function()
				Snacks.terminal.toggle()
			end,
			desc = "Toggle Floating Terminal",
		},
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
			"gD",
			function()
				Snacks.picker.lsp_declarations()
			end,
			desc = "Goto Declaration",
		},
		{
			"gy",
			function()
				Snacks.picker.lsp_type_definitions()
			end,
			desc = "Goto T[y]pe Definition",
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
