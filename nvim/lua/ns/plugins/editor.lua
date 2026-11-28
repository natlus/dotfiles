return {
	{
		"rmagatti/auto-session",
		lazy = false,
		opts = {
			-- `nvim -S <file>` (how Rex resumes Neovim) already loads a session.
			auto_restore = not vim.tbl_contains(vim.v.argv, "-S"),
			suppressed_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
		},
	},

	{
		"NMAC427/guess-indent.nvim",
	},

	{
		"ThePrimeagen/harpoon",
		branch = "harpoon2",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			local harpoon = require("harpoon")
			harpoon:setup({})

			local function toggle_snacks_picker(harpoon_files)
				local items = {}
				for idx, item in ipairs(harpoon_files.items) do
					table.insert(items, {
						idx = idx,
						file = item.value,
						text = item.value,
					})
				end

				Snacks.picker({
					title = "Harpoon",
					items = items,
					format = function(item)
						return { { item.idx .. ": ", "SnacksPickerIdx" }, { item.file } }
					end,
					confirm = function(picker, item)
						picker:close()
						if item then
							harpoon_files:select(item.idx)
						end
					end,
					actions = {
						delete = function(picker, item)
							if item then
								table.remove(harpoon_files.items, item.idx)
								if harpoon_files.save then
									harpoon_files:save()
								end
							end
							picker:close()
							toggle_snacks_picker(harpoon_files)
						end,
					},
					win = {
						input = {
							keys = {
								["dd"] = { "delete", mode = { "n" } },
								["<C-d>"] = { "delete", mode = { "n", "i" } },
							},
						},
					},
				})
			end

			vim.keymap.set("n", "<leader>e", function()
				toggle_snacks_picker(harpoon:list())
			end, { desc = "Open harpoon window" })

			vim.keymap.set("n", "<leader>a", function()
				harpoon:list():add()
			end)

			vim.keymap.set("n", "<leader>1", function()
				harpoon:list():select(1)
			end)
			vim.keymap.set("n", "<leader>2", function()
				harpoon:list():select(2)
			end)
			vim.keymap.set("n", "<leader>3", function()
				harpoon:list():select(3)
			end)
			vim.keymap.set("n", "<leader>4", function()
				harpoon:list():select(4)
			end)

			vim.keymap.set("n", "<C-P>", function()
				harpoon:list():prev()
			end)
			vim.keymap.set("n", "<C-N>", function()
				harpoon:list():next()
			end)
		end,
	},

	{
		"dmtrKovalenko/fff.nvim",
		enabled = true,
		build = function()
			-- downloads a prebuilt binary or falls back to cargo build
			require("fff.download").download_or_build_binary()
		end,

		lazy = false, -- the plugin lazy-initialises itself
		config = function()
			vim.api.nvim_set_hl(0, "FFFLiveGrepMatch", { fg = "#42A5F5", bg = "#575757" })

			require("fff").setup({
				debug = {
					enabled = false,
					show_scores = false,
				},
				title = " Open File ",
				max_threads = 4, -- Maximum threads for fuzzy search
				lazy_sync = true,
				git = {
					status_text_color = true,
				},

				layout = {
					width = 0.55,
					prompt_position = "top",
					preview_size = 0,
					min_list_height = 0,
				},
				preview = {
					enabled = false,
				},
				hl = {
					grep_match = "FFFLiveGrepMatch",
					git_staged = "GitSignsStage", -- Files staged for commit
					git_modified = "GitSignsChange", -- Modified unstaged files
					git_deleted = "GitSignsDelete", -- Deleted files
					git_renamed = "GitSignsRename", -- Renamed files
					git_added = "GitSignsAdd",
					winhl = {
						input = "Normal:NormalFloat,FloatBorder:FloatBorder,FloatTitle:Title,IncSearch:FFFLiveGrepMatch",
						list = "Normal:NormalFloat,FloatBorder:FloatBorder,FloatTitle:Title,IncSearch:FFFLiveGrepMatch",
					},
				},
				frecency = {
					enabled = true,
					db_path = vim.fn.stdpath("cache") .. "/fff_nvim",
				},
				history = {
					enabled = true,
					db_path = vim.fn.stdpath("data") .. "/fff_queries",
					min_combo_count = 3, -- file will get a boost if it was selected 3 in a row times per specific query
					combo_boost_score_multiplier = 100, -- Score multiplier for combo matches
				},
			})
		end,

		keys = {
			{
				"<leader>sf",
				function()
					require("fff").find_files()
				end,
				desc = "FFFind files",
			},
			{
				"<leader>/",
				function()
					require("fff").live_grep({
						grep = {
							modes = { "fuzzy", "plain" },
						},
					})
				end,
				desc = "LiFFFe grep",
			},
		},
	},

	{
		"nvim-mini/mini.nvim",
		config = function()
			require("mini.ai").setup({ n_lines = 500 })
			require("mini.surround").setup({
				mappings = {
					add = "gsa",
					delete = "gsd",
					find = "gsf",
					find_left = "gsF",
					highlight = "gsh",
					replace = "gsr",
					update_n_lines = "gsn",
				},
			})
			require("mini.move").setup({
				mappings = {
					down = "J",
					up = "K",
				},
			})
			require("mini.pairs").setup()
			require("mini.hipatterns").setup({
				highlighters = { hex_color = require("mini.hipatterns").gen_highlighter.hex_color() },
			})
			require("mini.diff").setup({
				-- show whole reference part above whole buffer part, as in `git diff`
				view = { overlay_style = "hunk" },
				mappings = { goto_next = "]c", goto_prev = "[c" },
			})

			local statusline = require("mini.statusline")
			vim.api.nvim_set_hl(0, "NsStatuslineBasename", { link = "StatusLine" })
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
						local git_modified = (git_status.added or 0)
								+ (git_status.changed or 0)
								+ (git_status.removed or 0)
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
							{ hl = select(2, statusline.section_mode({})), strings = { mode } },
							"%<",
							{
								hl = "MiniStatuslineFilename",
								strings = { path .. "%#NsStatuslineBasename#" .. basename },
							},
							{ hl = "MiniStatuslineDevinfo", strings = { git_info } },
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
	},

	{
		"JoosepAlviste/nvim-ts-context-commentstring",
		lazy = false,
		init = function()
			vim.g.skip_ts_context_commentstring_module = true
		end,
		config = function()
			require("ts_context_commentstring").setup({ enable_autocmd = false })

			local get_option = vim.filetype.get_option
			---@diagnostic disable-next-line: duplicate-set-field
			vim.filetype.get_option = function(filetype, option)
				if option == "commentstring" then
					return require("ts_context_commentstring.internal").calculate_commentstring()
						or get_option(filetype, option)
				end
				return get_option(filetype, option)
			end
		end,
	},

	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {
			preset = "helix",
		},
		keys = {
			{
				"<leader>?",
				function()
					require("which-key").show({ global = false })
				end,
				desc = "Buffer Local Keymaps (which-key)",
			},
		},
	},

	{
		"folke/todo-comments.nvim",
		event = "VeryLazy",
		opts = {},
		keys = {
			{
				"]t",
				function()
					require("todo-comments").jump_next()
				end,
				desc = "Next todo",
			},
			{
				"[t",
				function()
					require("todo-comments").jump_prev()
				end,
				desc = "Previous todo",
			},
			{
				"<leader>st",
				function()
					Snacks.picker.todo_comments()
				end,
				desc = "Todo comments",
			},
		},
	},

	{
		"folke/trouble.nvim",
		cmd = "Trouble",
		opts = {},
		keys = {
			{ "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
			{ "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer diagnostics (Trouble)" },
			{ "<leader>xs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Symbols (Trouble)" },
			{ "<leader>xq", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix list (Trouble)" },
			{ "<leader>xt", "<cmd>Trouble todo toggle<cr>", desc = "Todos (Trouble)" },
		},
	},
}
