local function find_up(names, ctx)
	return vim.fs.find(names, { path = ctx.filename, upward = true })[1] ~= nil
end

local function package_json(ctx)
	local path = vim.fs.find("package.json", { path = ctx.filename, upward = true })[1]
	local ok, package = pcall(function()
		return vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))
	end)
	return path and ok and package or {}
end

-- true if package.json depends on any of `deps` or a script mentions oxfmt
local function package_uses(package, deps)
	for _, group in ipairs({ "dependencies", "devDependencies", "peerDependencies", "optionalDependencies" }) do
		for _, dep in ipairs(deps) do
			if (package[group] or {})[dep] then
				return true
			end
		end
	end
	for _, script in pairs(package.scripts or {}) do
		if type(script) == "string" and script:find("oxfmt", 1, true) then
			return true
		end
	end
	return false
end

local function has_oxfmt_config(_, ctx)
	local ft = vim.bo[ctx.buf].filetype
	return ft == "json"
		or ft == "jsonc"
		or find_up({ ".oxfmtrc.json", ".oxfmtrc.jsonc", "oxfmt.config.ts", "vite.config.ts", "vite.config.js" }, ctx)
		or package_uses(package_json(ctx), { "oxfmt" })
end

-- prettier only where the project has no oxc tooling
local function has_prettier_config(_, ctx)
	if has_oxfmt_config(nil, ctx) or find_up({ "oxlint.json", ".oxlintrc.json" }, ctx) then
		return false
	end
	local package = package_json(ctx)
	if package_uses(package, { "oxc", "oxlint", "@oxc-project/runtime" }) then
		return false
	end
	return package.prettier ~= nil
		or find_up({
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
		}, ctx)
end

return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	keys = {
		{
			"<leader>cf",
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
			javascript = { "oxfmt", "prettierd", "prettier", stop_after_first = true },
			javascriptreact = { "oxfmt", "prettierd", "prettier", stop_after_first = true },
			typescript = { "oxfmt", "prettierd", "prettier", stop_after_first = true },
			typescriptreact = { "oxfmt", "prettierd", "prettier", stop_after_first = true },
			astro = { "oxfmt", "prettierd", "prettier", stop_after_first = true },
			json = { "oxfmt" },
			jsonc = { "oxfmt" },
			yaml = { "oxfmt", "prettierd", "prettier", stop_after_first = true },
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
}
