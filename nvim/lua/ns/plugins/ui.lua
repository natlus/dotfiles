return {
	{
		"slugbyte/lackluster.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			-- lackluster palette: lack #708090, luster #deeeed, orange #ffaa88, green #789978, blue #7788aa, red #d70000
			local c = {
				comment = "#5f5f5f",
				keyword = "#8e8e8e",
				dim = "#7a7a7a",
				mid = "#aaaaaa",
				text = "#cccccc",
				bright = "#deeeed",
				lack = "#708090",
				blue = "#7788aa",
				green = "#789978",
				orange = "#ffaa88",
				red = "#d70000",
				select = "#333333",
				accent = "#ffffff",
			}
			local hl = {}
			-- vesper-style tiers: one warm accent for functions/types/constants (incl. @lsp.*, since tsc's
			-- semantic tokens win over treesitter); zenbones-style: keywords get weight, not brightness
			for _, name in ipairs({
				"Function", "@function", "@function.call", "@function.method",
				"@function.method.call", "@function.builtin", "@constructor", "Type",
				"@type", "@type.builtin", "@type.definition", "Constant",
				"@constant", "@constant.builtin", "Number", "@number",
				"@number.float", "Boolean", "@boolean", "@string.escape",
				"@import.name", "@lsp.type.function", "@lsp.type.method", "@lsp.type.class",
				"@lsp.type.interface", "@lsp.type.type", "@lsp.type.typeParameter", "@lsp.type.enum",
				"@lsp.type.enumMember", "@tag",
			}) do
				hl[name] = { fg = c.accent }
			end
			for _, name in ipairs({
				"Statement", "Keyword", "Conditional", "Repeat",
				"Exception", "Include", "@keyword", "@keyword.function",
				"@keyword.return", "@keyword.conditional", "@keyword.conditional.ternary", "@keyword.repeat",
				"@keyword.import", "@keyword.operator", "@keyword.exception", "@keyword.modifier",
				"@keyword.type", "@keyword.coroutine",
			}) do
				hl[name] = { fg = c.keyword, bold = true }
			end
			require("lackluster").setup({
				tweak_background = { normal = "none" },
				-- lift the most muted syntax (stock comments #3a3a3a, keywords #666666)
				tweak_syntax = {
					comment = c.comment,
					keyword = c.keyword,
					keyword_return = c.keyword,
					keyword_exception = c.keyword,
					builtin = c.mid,
				},
				tweak_highlight = vim.tbl_extend("force", hl, {
					["@variable"] = { fg = c.text },
					["@variable.member"] = { fg = c.text },
					["@variable.parameter"] = { fg = c.text },
					["@property"] = { fg = c.text },
					["@variable.builtin"] = { fg = c.keyword },
					["@operator"] = { fg = c.keyword },
					Operator = { fg = c.keyword },
					["@punctuation.bracket"] = { fg = c.dim },
					["@punctuation.delimiter"] = { fg = c.dim },
					["@lsp.type.namespace"] = { fg = c.mid },
					["@lsp.type.variable"] = { fg = c.text },
					["@lsp.type.property"] = { fg = c.text },
					["@lsp.type.parameter"] = { fg = c.text },
					["@lsp.typemod.variable.readonly"] = { fg = c.text },
					["@lsp.typemod.variable.defaultLibrary"] = { fg = c.mid },
					CursorLineNr = { bold = true },
					Directory = { fg = c.mid, bold = true },
					Todo = { bold = true },
					CurSearch = { bold = true },
					IncSearch = { bold = true },
					["@comment.documentation"] = { fg = c.comment },
					SpecialComment = { fg = c.comment },
					["@label"] = { fg = c.dim },
					["@tag.builtin"] = { fg = c.mid },
					["@tag.attribute"] = { fg = c.dim },

					-- diagnostics were #444444 (invisible); trouble/todo/tiny-inline follow these
					DiagnosticError = { fg = c.red },
					DiagnosticWarn = { fg = c.orange },
					DiagnosticInfo = { fg = c.blue },
					DiagnosticHint = { fg = c.lack },
					DiagnosticOk = { fg = c.green },
					DiagnosticVirtualTextError = { fg = c.red },
					DiagnosticVirtualTextWarn = { fg = c.orange },
					DiagnosticVirtualTextInfo = { fg = c.blue },
					DiagnosticVirtualTextHint = { fg = c.lack },
					DiagnosticUnderlineInfo = { undercurl = true, sp = c.blue },
					DiagnosticUnderlineHint = { undercurl = true, sp = c.lack },
					["@comment.warning"] = { fg = c.orange },

					-- headings, markup, structure
					Title = { fg = c.bright, bold = true },
					FloatTitle = { fg = c.mid, bold = true },
					["@markup.heading"] = { fg = c.bright, bold = true },
					["@markup.strong"] = { fg = c.text, bold = true },
					["@markup.italic"] = { fg = c.text, italic = true },
					["@markup.strikethrough"] = { fg = c.dim, strikethrough = true },
					["@markup.link.url"] = { fg = c.blue, underline = true },
					["@markup.list"] = { fg = c.dim },
					Folded = { fg = c.dim },
					WhichKey = { fg = c.blue },
					WhichKeyDesc = { fg = c.mid },
					WhichKeyGroup = { fg = c.text },
					TroubleNormal = { fg = c.text },
					TroubleNormalNC = { fg = c.text },

					-- bright #cccccc blocks toned down (search keeps its strong highlight)
					LspReferenceText = { fg = "none", bg = c.select, overwrite = true },
					LspReferenceRead = { fg = "none", bg = c.select, overwrite = true },
					LspReferenceWrite = { fg = "none", bg = c.select, underline = true, overwrite = true },
					PmenuSel = { fg = c.bright, bg = c.select, overwrite = true },
					BlinkCmpMenuSelection = { fg = c.bright, bg = c.select, overwrite = true },

					-- groups lackluster leaves undefined
					BlinkCmpLabelMatch = { fg = c.blue, bold = true },
					SnacksPickerMatch = { fg = c.blue, bold = true },
					CopilotSuggestion = { fg = c.comment, italic = true },
				}),
			})
			local subtle
			-- theme-agnostic statusline/scrollbar tweaks, re-applied whenever a colorscheme loads
			vim.api.nvim_create_autocmd("ColorScheme", {
				group = vim.api.nvim_create_augroup("ns-ui-tweaks", { clear = true }),
				callback = function()
					local get = function(name)
						return vim.api.nvim_get_hl(0, { name = name, link = false })
					end
					-- remember the theme grey: on a re-run StatusLine.bg is already cleared
					subtle = get("StatusLine").bg or subtle or get("Visual").bg
					-- transparent statusline: section backgrounds looked patchy and the terminal
					-- stretched the last row's background into its padding
					for _, name in ipairs({
						"StatusLine",
						"StatusLineNC",
						"MiniStatuslineFilename",
						"MiniStatuslineFileinfo",
						"MiniStatuslineDevinfo",
						"MiniStatuslineInactive",
					}) do
						vim.api.nvim_set_hl(0, name, { fg = get(name).fg })
					end
					-- some themes make StatusLine text a near-invisible "filler" grey; sections without
					-- their own group (e.g. location) inherit it, so borrow mini's readable colors
					vim.api.nvim_set_hl(0, "StatusLine", { fg = get("MiniStatuslineFileinfo").fg })
					vim.api.nvim_set_hl(0, "StatusLineNC", { fg = get("MiniStatuslineInactive").fg })
					-- mode label as colored text; fall back to its fg when its bg is just the statusline grey
					for _, mode in ipairs({ "Normal", "Insert", "Visual", "Replace", "Command", "Other" }) do
						local name = "MiniStatuslineMode" .. mode
						local h = get(name)
						vim.api.nvim_set_hl(0, name, { fg = (h.bg and h.bg ~= subtle) and h.bg or h.fg, bold = true })
					end
					vim.api.nvim_set_hl(0, "SatelliteBar", { bg = subtle })
					-- picker selection: subtle row instead of Visual (lackluster's Visual is near-white)
					local fg = get("Normal").fg or 0xcccccc
					local mix = function(a, b, t) -- blend each RGB channel of a toward b by t
						local out = 0
						for shift = 0, 16, 8 do
							local ca, cb = bit.band(bit.rshift(a, shift), 255), bit.band(bit.rshift(b, shift), 255)
							out = out + bit.lshift(math.floor(ca + (cb - ca) * t + 0.5), shift)
						end
						return out
					end
					vim.api.nvim_set_hl(0, "NsPickerCursorLine", { bg = mix(subtle, fg, 0.1) })
					vim.api.nvim_set_hl(0, "SnacksPickerListCursorLine", { link = "NsPickerCursorLine" })
				end,
			})
			vim.cmd.colorscheme("lackluster")
		end,
	},
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
				matcher = {
					sort_empty = true,
					history_bonus = true,
					frecency = true,
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
				"grr",
				function()
					Snacks.picker.lsp_references()
				end,
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
