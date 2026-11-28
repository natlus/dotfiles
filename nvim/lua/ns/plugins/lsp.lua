-- Server overrides live in after/lsp/<name>.lua; vim.lsp merges them over nvim-lspconfig's defaults.
-- blink.cmp registers its capabilities for every server on its own.
local servers = { "astro", "oxlint", "tsc", "tailwindcss", "lua_ls" }

return {
	{
		"folke/lazydev.nvim",
		ft = "lua",
		opts = {
			library = {
				{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
			},
		},
	},

	{
		"neovim/nvim-lspconfig",
		dependencies = {
			{ "mason-org/mason.nvim", opts = {} },
			{
				"WhoIsSethDaniel/mason-tool-installer.nvim",
				opts = {
					ensure_installed = {
						"astro-language-server",
						"lua-language-server",
						"oxfmt",
						"oxlint",
						"stylua",
						"tailwindcss-language-server",
						"tsc",
						-- only provides a standard `typescript/lib` tsdk for the astro LSP
						"typescript-language-server",
					},
				},
			},
			"saghen/blink.cmp",
		},
		config = function()
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("ns-lsp-attach", { clear = true }),
				callback = function(event)
					-- grn/gra/grr/gri/grt/gO are Neovim defaults
					vim.keymap.set(
						"n",
						"grD",
						vim.lsp.buf.declaration,
						{ buffer = event.buf, desc = "LSP: Declaration" }
					)
					vim.keymap.set("n", "<leader>th", function()
						vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
					end, { buffer = event.buf, desc = "LSP: Toggle inlay hints" })
				end,
			})

			-- LSP progress through snacks.notifier
			vim.api.nvim_create_autocmd("LspProgress", {
				group = vim.api.nvim_create_augroup("ns-lsp-progress", { clear = true }),
				callback = function(ev)
					local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
					vim.notify(vim.lsp.status(), vim.log.levels.INFO, {
						id = "lsp_progress",
						title = "LSP Progress",
						opts = function(notif)
							notif.icon = ev.data.params.value.kind == "end" and " "
								or spinner[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1]
						end,
					})
				end,
			})

			vim.diagnostic.config({
				severity_sort = true,
				float = { border = "rounded", source = "if_many" },
				underline = {},
				signs = {
					text = {
						[vim.diagnostic.severity.ERROR] = "󰅚 ",
						[vim.diagnostic.severity.WARN] = "󰀪 ",
						[vim.diagnostic.severity.INFO] = "󰋽 ",
						[vim.diagnostic.severity.HINT] = "󰌶 ",
					},
				},
			})

			vim.lsp.enable(servers)
		end,
	},

	{
		"saghen/blink.cmp",
		version = "1.*",
		---@module 'blink.cmp'
		---@type blink.cmp.Config
		opts = {
			keymap = {
				preset = "default",
				["<CR>"] = { "select_and_accept", "fallback" },
			},
			appearance = { nerd_font_variant = "mono" },
			completion = {
				documentation = { auto_show = true },
				accept = { auto_brackets = { enabled = true } },
			},
			-- replaces noice's signature popup
			signature = { enabled = true },
			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
			},
			fuzzy = { implementation = "prefer_rust_with_warning" },
		},
		opts_extend = { "sources.default" },
	},
}
