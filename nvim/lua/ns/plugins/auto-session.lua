return {
	"rmagatti/auto-session",
	lazy = false,
	opts = {
		-- `nvim -S <file>` (how Rex resumes Neovim) already loads a session.
		auto_restore = not vim.tbl_contains(vim.v.argv, "-S"),
		suppressed_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
	},
}
