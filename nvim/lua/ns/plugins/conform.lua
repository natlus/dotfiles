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
			javascript = { "oxfmt", "prettierd", "prettier", stop_after_first = true },
			javascriptreact = { "oxfmt", "prettierd", "prettier", stop_after_first = true },
			typescript = { "oxfmt", "prettierd", "prettier", stop_after_first = true },
			typescriptreact = { "oxfmt", "prettierd", "prettier", stop_after_first = true },
			astro = { "oxfmt", "prettierd", "prettier", stop_after_first = true },
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
}
