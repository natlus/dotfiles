local root_markers = { ".oxlintrc.json", ".oxlintrc.jsonc", "oxlint.config.ts", "oxlint.json", "package.json", ".git" }

return {
	root_dir = function(bufnr, on_dir)
		on_dir(vim.fs.root(bufnr, root_markers))
	end,
	filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "astro" },
}
