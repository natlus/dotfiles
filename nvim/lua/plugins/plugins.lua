local function project_root(ctx)
	return vim.fs.root(ctx.filename, {
		".git",
		"package.json",
		".prettierrc",
		"prettier.config.js",
		"oxlint.json",
		".oxlintrc.json",
	}) or vim.fs.dirname(ctx.filename)
end

local function package_json(ctx)
	local path = vim.fs.joinpath(project_root(ctx), "package.json")
	if vim.fn.filereadable(path) == 0 then
		return nil
	end

	local ok, package = pcall(vim.json.decode, table.concat(vim.fn.readfile(path), "\n"))
	if not ok then
		return nil
	end

	return package
end

local function has_oxfmt_config(_, ctx)
	if vim.fs.find({
		".oxfmtrc.json",
		".oxfmtrc.jsonc",
		"oxfmt.config.ts",
		"vite.config.ts",
		"vite.config.js",
	}, { path = ctx.filename, upward = true })[1] ~= nil then
		return true
	end

	local package = package_json(ctx)
	if not package then
		return false
	end

	local dependency_groups = { "dependencies", "devDependencies", "peerDependencies", "optionalDependencies" }
	for _, group in ipairs(dependency_groups) do
		local dependencies = package[group]
		if dependencies and dependencies.oxfmt then
			return true
		end
	end

	for _, script in pairs(package.scripts or {}) do
		if type(script) == "string" and script:find("oxfmt", 1, true) then
			return true
		end
	end

	return false
end

local function has_oxc_config(_, ctx)
	if has_oxfmt_config(nil, ctx) then
		return true
	end

	if
		vim.fs.find({
			"oxlint.json",
			".oxlintrc.json",
		}, { path = ctx.filename, upward = true })[1] ~= nil
	then
		return true
	end

	local package = package_json(ctx)
	if not package then
		return false
	end

	local dependency_groups = { "dependencies", "devDependencies", "peerDependencies", "optionalDependencies" }
	for _, group in ipairs(dependency_groups) do
		local dependencies = package[group]
		if dependencies and (dependencies.oxc or dependencies.oxfmt or dependencies.oxlint or dependencies["@oxc-project/runtime"]) then
			return true
		end
	end

	for _, script in pairs(package.scripts or {}) do
		if type(script) == "string" and script:find("oxfmt", 1, true) then
			return true
		end
	end

	return false
end

local function has_prettier_config(_, ctx)
	if has_oxc_config(nil, ctx) then
		return false
	end

	if
		vim.fs.find({
			".prettierrc",
			".prettierrc.json",
			".prettierrc.json5",
			".prettierrc.yaml",
			".prettierrc.yml",
			".prettierrc.toml",
			".prettierrc.js",
			".prettierrc.cjs",
			".prettierrc.mjs",
			".prettierrc.ts",
			".prettierrc.cts",
			".prettierrc.mts",
			"prettier.config.js",
			"prettier.config.cjs",
			"prettier.config.mjs",
			"prettier.config.ts",
			"prettier.config.cts",
			"prettier.config.mts",
		}, { path = ctx.filename, upward = true })[1] ~= nil
	then
		return true
	end

	local package = package_json(ctx)
	return package and package.prettier ~= nil
end

return {

	{ -- custom theme
		require("vesper-ns").setup(),
	},

	"NMAC427/guess-indent.nvim",
	"justinmk/vim-sneak",

	{
		"lewis6991/gitsigns.nvim",
		opts = {
			signs = {
				add = { text = "▌" },
				change = { text = "▌" },
				delete = { text = "󰍟" },
				topdelete = { text = "󰍟" },
				changedelete = { text = "~" },
				untracked = { text = "┆" },
			},
			signs_staged_enable = false,
			current_line_blame = true,
			current_line_blame_opts = {
				delay = 0,
			},
			current_line_blame_formatter_nc = "",
			current_line_blame_formatter = "     <author>, <author_time:%R>",
		},
	},

	{
		"rmagatti/auto-session",
		lazy = false,
		opts = {
			suppressed_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
		},
	},

	{
		"nvim-telescope/telescope.nvim",
		event = "VimEnter",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{ -- If encountering errors, see telescope-fzf-native README for installation instructions
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "make",
				cond = function()
					return vim.fn.executable("make") == 1
				end,
			},
			{ "nvim-telescope/telescope-ui-select.nvim" },

			-- Useful for getting pretty icons, but requires a Nerd Font.
			{ "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
		},
		config = function()
			require("telescope").setup({
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown(),
					},
				},
			})

			-- Enable Telescope extensions if they are installed
			pcall(require("telescope").load_extension, "fzf")
			pcall(require("telescope").load_extension, "ui-select")

			-- See `:help telescope.builtin`
			local builtin = require("telescope.builtin")
			vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "[S]earch [H]elp" })
			vim.keymap.set("n", "<leader>sk", builtin.keymaps, { desc = "[S]earch [K]eymaps" })
			vim.keymap.set("n", "<leader>sf", builtin.find_files, { desc = "[S]earch [F]iles" })
			vim.keymap.set("n", "<leader>ss", builtin.builtin, { desc = "[S]earch [S]elect Telescope" })
			vim.keymap.set("n", "<leader>sw", builtin.grep_string, { desc = "[S]earch current [W]ord" })
			vim.keymap.set("n", "<leader>sg", builtin.live_grep, { desc = "[S]earch by [G]rep" })
			vim.keymap.set("n", "<leader>sd", builtin.diagnostics, { desc = "[S]earch [D]iagnostics" })
			vim.keymap.set("n", "<leader>sr", builtin.resume, { desc = "[S]earch [R]esume" })
			vim.keymap.set("n", "<leader>s.", builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
			-- vim.keymap.set("n", "<leader><leader>", builtin.buffers, { desc = "[ ] Find existing buffers" })

			-- Slightly advanced example of overriding default behavior and theme
			vim.keymap.set("n", "<leader>/", function()
				-- You can pass additional configuration to Telescope to change the theme, layout, etc.
				builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
					winblend = 10,
					previewer = false,
				}))
			end, { desc = "[/] Fuzzily search in current buffer" })

			-- It's also possible to pass additional configuration options.
			--  See `:help telescope.builtin.live_grep()` for information about particular keys
			vim.keymap.set("n", "<leader>s/", function()
				builtin.live_grep({
					grep_open_files = true,
					prompt_title = "Live Grep in Open Files",
				})
			end, { desc = "[S]earch [/] in Open Files" })

			-- Shortcut for searching your Neovim configuration files
			vim.keymap.set("n", "<leader>sn", function()
				builtin.find_files({ cwd = vim.fn.stdpath("config") })
			end, { desc = "[S]earch [N]eovim files" })
		end,
	},

	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		keys = {
			{
				"<leader>f",
				function()
					require("conform").format({ async = true, lsp_format = "fallback" })
				end,
				mode = "",
				desc = "[F]ormat buffer",
			},
		},
		opts = {
			notify_on_error = false,
			format_on_save = function(bufnr)
				local disable_filetypes = { c = true, cpp = true }
				if disable_filetypes[vim.bo[bufnr].filetype] then
					return nil
				else
					return {
						timeout_ms = 500,
						lsp_format = "fallback",
					}
				end
			end,
			formatters_by_ft = {
				lua = { "stylua" },
				-- You can use 'stop_after_first' to run the first available formatter from the list
				javascript = { "oxfmt", "prettierd", "prettier", stop_after_first = true },
				javascriptreact = { "oxfmt", "prettierd", "prettier", stop_after_first = true },
				typescript = { "oxfmt", "prettierd", "prettier", stop_after_first = true },
				typescriptreact = { "oxfmt", "prettierd", "prettier", stop_after_first = true },
				json = { "oxfmt", "prettierd", "prettier", stop_after_first = true },
				jsonc = { "oxfmt", "prettierd", "prettier", stop_after_first = true },
			},
			formatters = {
				oxfmt = {
					condition = has_oxfmt_config,
				},
				prettier = {
					condition = has_prettier_config,
				},
				prettierd = {
					condition = has_prettier_config,
				},
			},
		},
	},

	{
		"echasnovski/mini.nvim",
		config = function()
			require("mini.ai").setup({ n_lines = 500 })
			require("mini.surround").setup({
				mappings = {
					add = "sa", -- Add surrounding in Normal and Visual modes
					delete = "ds", -- Delete surrounding
					find = "fs", -- Find surrounding (to the right)
					replace = "rs", -- Replace surrounding
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
				use_icons = false,
			})

			---@diagnostic disable-next-line: duplicate-set-field
			statusline.section_location = function()
				return "%2l:%-2v"
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
		"ThePrimeagen/harpoon",
		branch = "harpoon2",
		dependencies = { "nvim-lua/plenary.nvim" },
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
						signs = { -- can only be a single character (multibyte is okay)
							add = "▌",
							change = "▌",
							delete = "▌",
						},
					},
					marks = {
						enable = true,
						key = "m",
						show_builtins = false, -- shows the builtin marks like [ ] < >
					},
				},
			})
		end,
	},

	{
		"nickjvandyke/opencode.nvim",
		version = "*", -- Latest stable release
		config = function()
			---@type opencode.Opts
			vim.g.opencode_opts = {
				-- Your configuration, if any; goto definition on the type or field for details
			}

			vim.o.autoread = true -- Required for `vim.g.opencode_opts.events.reload`

			-- Recommended/example keymaps
			vim.keymap.set({ "n", "x" }, "<leader>oa", function()
				require("opencode").ask("@this: ")
			end, { desc = "Ask OpenCode…" })
			vim.keymap.set({ "n", "x" }, "<leader>os", function()
				require("opencode").select()
			end, { desc = "Select OpenCode…" })

			vim.keymap.set({ "n", "x" }, "go", function()
				return require("opencode").operator("@this ")
			end, { desc = "Append range to OpenCode", expr = true })
			vim.keymap.set("n", "goo", function()
				return require("opencode").operator("@this ") .. "_"
			end, { desc = "Append line to OpenCode", expr = true })

			vim.keymap.set("n", "<S-C-u>", function()
				require("opencode").command("session.half.page.up")
			end, { desc = "Scroll OpenCode up" })
			vim.keymap.set("n", "<S-C-d>", function()
				require("opencode").command("session.half.page.down")
			end, { desc = "Scroll OpenCode down" })
		end,
	},

	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		---@type snacks.Config
		opts = {
			-- your configuration comes here
			-- or leave it empty to use the default settings
			-- refer to the configuration section below
			bigfile = { enabled = true },
			dashboard = { enabled = true },
			explorer = { enabled = true },
			indent = { enabled = true },
			input = { enabled = true }, -- Enhances opencode.nvim `ask()`
			picker = {
				enabled = true, -- Enhances opencode.nvim `select()`
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
			},
			notifier = { enabled = true },
			quickfile = { enabled = true },
			scope = { enabled = true },
			scroll = { enabled = true },
			statuscolumn = { enabled = true },
			words = { enabled = true },
		},
	},
}
