local function tsdk(root_dir)
	local project_ts = vim.fs.joinpath(root_dir or vim.fn.getcwd(), "node_modules/typescript/lib")
	if vim.fn.isdirectory(project_ts) == 1 then
		return project_ts
	end
	-- fall back to mason's typescript copy (installed alongside typescript-language-server)
	return vim.fs.joinpath(
		vim.fn.stdpath("data"),
		"mason/packages/typescript-language-server/node_modules/typescript/lib"
	)
end

return {
	before_init = function(_, config)
		config.init_options = config.init_options or {}
		config.init_options.typescript = { tsdk = tsdk(config.root_dir) }
	end,
}
