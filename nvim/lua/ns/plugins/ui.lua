return {
	{ "nvim-tree/nvim-web-devicons", opts = {} },

	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		---@type snacks.Config
		opts = {
			terminal = {
				enabled = true,
				win = {
					position = "float",
					width = 0.8,
					height = 0.65,
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
				---@type snacks.picker.Config
				layout = {
					preset = "select",
					preview = false,
				},
				win = {
					input = {
						title = " Open File ",
						title_pos = "center",
						wo = {
							winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,FloatTitle:Title,IncSearch:SnacksPickerMatch",
						},
					},
					list = {
						wo = {
							winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,FloatTitle:Title,IncSearch:SnacksPickerMatch",
						},
					},
				},
				sources = {
					files = {
						hidden = true,
						ignored = true,
						exclude = { ".next", ".next-dev", "node_modules" },
					},
				},
				matcher = {
					sort_empty = true,
					history_bonus = true,
					frecency = true,
				},
				formatters = {
					file = {
						filename_first = true,
					},
				},
			},
			notifier = { enabled = true },
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
		},
	},

	{
		"lewis6991/satellite.nvim",
		config = function()
			require("satellite").setup({
				current_only = false,
				winblend = 50,
				zindex = 40,
				excluded_filetypes = {},
				width = 2,
				handlers = {
					cursor = {
						enable = true,
						symbols = { "", "", "", "" },
					},
					search = {
						enable = true,
					},
					diagnostic = {
						enable = true,
						signs = { "-", "=", "≡" },
						min_severity = vim.diagnostic.severity.HINT,
					},
					gitsigns = {
						enable = true,
						signs = {
							add = "",
							change = "",
							delete = "",
						},
					},
					marks = {
						enable = true,
						key = "m",
						show_builtins = false,
					},
				},
			})
		end,
	},

	{
		"rachartier/tiny-inline-diagnostic.nvim",
		event = "VeryLazy",
		priority = 1000,
		config = function()
			require("tiny-inline-diagnostic").setup({
				preset = "simple",
				options = {
					show_all_diags_on_cursorline = false,
					show_code = false,
					enable_on_insert = true,
					add_messages = {
						messages = true,
						display_count = false,
						use_max_severity = true,
						show_multiple_glyphs = true,
					},
					multilines = {
						enabled = true,
					},
					show_related = {
						enabled = false,
					},
					severity = {
						vim.diagnostic.severity.ERROR,
						vim.diagnostic.severity.WARN,
						vim.diagnostic.severity.INFO,
					},

					format = function(diag)
						local msg = tostring(diag.message):gsub("\n.*", "")
						return msg
					end,
				},
			})
			vim.diagnostic.config({ virtual_text = false }) -- Disable Neovim's default virtual text diagnostics
		end,
	},
}
