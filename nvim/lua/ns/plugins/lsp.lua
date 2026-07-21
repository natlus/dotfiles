return {
	{
		"folke/lazydev.nvim",
		ft = "lua",
		opts = {
			library = {
				-- Load luvit types when the `vim.uv` word is found
				{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
			},
		},
	},

	{
		"neovim/nvim-lspconfig",
		dependencies = {
			{ "mason-org/mason.nvim", opts = {} },
			"mason-org/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			{ "j-hui/fidget.nvim", opts = {} },
			"saghen/blink.cmp",
		},
		config = function()
			local lsp_attach = vim.api.nvim_create_augroup("ns-lsp-attach", { clear = true })
			local lsp_highlight = vim.api.nvim_create_augroup("ns-lsp-highlight", { clear = true })

			vim.api.nvim_create_autocmd("LspAttach", {
				group = lsp_attach,
				callback = function(event)
					local client = vim.lsp.get_client_by_id(event.data.client_id)
					if not client then
						return
					end

					local map = function(keys, func, desc, mode)
						mode = mode or "n"
						vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
					end

					map("grn", vim.lsp.buf.rename, "[R]e[n]ame")
					map("gra", vim.lsp.buf.code_action, "[G]oto Code [A]ction", { "n", "x" })
					map("grD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

					if client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
						vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
							buffer = event.buf,
							group = lsp_highlight,
							callback = vim.lsp.buf.document_highlight,
						})

						vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
							buffer = event.buf,
							group = lsp_highlight,
							callback = vim.lsp.buf.clear_references,
						})
					end

					if client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
						map("<leader>th", function()
							vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
						end, "[T]oggle Inlay [H]ints")
					end
				end,
			})

			vim.api.nvim_create_autocmd("LspDetach", {
				group = vim.api.nvim_create_augroup("ns-lsp-detach", { clear = true }),
				callback = function(event)
					vim.lsp.buf.clear_references()
					vim.api.nvim_clear_autocmds({ group = lsp_highlight, buffer = event.buf })
				end,
			})

			vim.diagnostic.config({
				severity_sort = true,
				float = { border = "rounded", source = "if_many" },
				underline = {},
				signs = vim.g.have_nerd_font and {
					text = {
						[vim.diagnostic.severity.ERROR] = "󰅚 ",
						[vim.diagnostic.severity.WARN] = "󰀪 ",
						[vim.diagnostic.severity.INFO] = "󰋽 ",
						[vim.diagnostic.severity.HINT] = "󰌶 ",
					},
				} or {},
			})

			local capabilities = require("blink.cmp").get_lsp_capabilities()
			local js_root_markers = {
				".oxlintrc.json",
				".oxlintrc.jsonc",
				"oxlint.config.ts",
				"oxlint.json",
				"package.json",
				".git",
			}

			local function js_root_dir(bufnr, on_dir)
				local filename = type(bufnr) == "number" and vim.api.nvim_buf_get_name(bufnr) or bufnr
				local root = vim.fs.root(filename, js_root_markers)

				if on_dir then
					return on_dir(root)
				end

				return root
			end

			local function astro_tsdk(root_dir)
				local project_ts = vim.fs.joinpath(root_dir or vim.fn.getcwd(), "node_modules/typescript/lib")
				if vim.fn.isdirectory(project_ts) == 1 then
					return project_ts
				end
				-- fall back to mason's typescript copy (installed alongside ts_ls)
				return vim.fs.joinpath(
					vim.fn.stdpath("data"),
					"mason/packages/typescript-language-server/node_modules/typescript/lib"
				)
			end

			local servers = {
				astro = {
					before_init = function(_, config)
						config.init_options = config.init_options or {}
						config.init_options.typescript = {
							tsdk = astro_tsdk(config.root_dir),
						}
					end,
				},
				oxlint = {
					root_dir = js_root_dir,
					filetypes = {
						"javascript",
						"javascriptreact",
						"typescript",
						"typescriptreact",
						"astro",
					},
				},
				tsgo = {
					settings = {
						typescript = {
							preferences = {
								importModuleSpecifier = "non-relative",
							},
						},
						javascript = {
							preferences = {
								importModuleSpecifier = "non-relative",
							},
						},
					},
				},
				lua_ls = {
					settings = {
						Lua = {
							completion = {
								callSnippet = "Replace",
							},
						},
					},
				},
			}

			local ensure_installed = vim.tbl_keys(servers or {})
			vim.list_extend(ensure_installed, {
				"oxfmt",
				"oxlint",
				"stylua",
				-- kept only to provide a standard `typescript/lib` tsdk for the astro LSP;
				-- tsgo (the Go binary) is not a valid tsdk for astro.
				"typescript-language-server",
			})
			require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

			require("mason-lspconfig").setup({
				ensure_installed = vim.tbl_keys(servers),
				automatic_enable = false,
			})

			for server_name, server in pairs(servers) do
				server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
				vim.lsp.config(server_name, server)
				vim.lsp.enable(server_name)
			end
		end,
	},

	{ -- Highlight, edit, and navigate code
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		main = "nvim-treesitter.config", -- Sets main module to use for opts
		-- [[ Configure Treesitter ]] See `:help nvim-treesitter`
		opts = {
			ensure_installed = {
				"astro",
				"bash",
				"c",
				"diff",
				"html",
				"lua",
				"luadoc",
				"markdown",
				"markdown_inline",
				"query",
				"vim",
				"vimdoc",
			},
			-- Autoinstall languages that are not installed
			auto_install = true,
			highlight = {
				enable = true,
				-- Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
				--  If you are experiencing weird indenting issues, add the language to
				--  the list of additional_vim_regex_highlighting and disabled languages for indent.
				additional_vim_regex_highlighting = { "ruby" },
			},
			indent = { enable = true, disable = { "ruby" } },
		},
		-- There are additional nvim-treesitter modules that you can use to interact
		-- with nvim-treesitter. You should go explore a few and see what interests you:
		--
		--    - Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
		--    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
		--    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
	},

	{
		"saghen/blink.cmp",
		-- optional: provides snippets for the snippet source
		-- dependencies = { "rafamadriz/friendly-snippets" },

		-- use a release tag to download pre-built binaries
		version = "1.*",
		-- AND/OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
		-- build = 'cargo build --release',
		-- If you use nix, you can build from source using latest nightly rust with:
		-- build = 'nix run .#build-plugin',

		---@module 'blink.cmp'
		---@type blink.cmp.Config
		opts = {
			-- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
			-- 'super-tab' for mappings similar to vscode (tab to accept)
			-- 'enter' for enter to accept
			-- 'none' for no mappings
			--
			-- All presets have the following mappings:
			-- C-space: Open menu or open docs if already open
			-- C-n/C-p or Up/Down: Select next/previous item
			-- C-e: Hide menu
			-- C-k: Toggle signature help (if signature.enabled = true)
			--
			-- See :h blink-cmp-config-keymap for defining your own keymap
			keymap = {
				preset = "default",
				["<CR>"] = { "select_and_accept", "fallback" },
			},

			appearance = {
				-- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
				-- Adjusts spacing to ensure icons are aligned
				nerd_font_variant = "mono",
			},

			completion = {
				documentation = { auto_show = true },
				accept = { auto_brackets = { enabled = true } },
			},

			-- Default list of enabled providers defined so that you can extend it
			-- elsewhere in your config, without redefining it, due to `opts_extend`
			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
			},

			-- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
			-- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
			-- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
			--
			-- See the fuzzy documentation for more information
			fuzzy = { implementation = "prefer_rust_with_warning" },

			version = "1.*",
		},
		opts_extend = { "sources.default" },
	},
}
