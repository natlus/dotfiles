return {
	"cursortab/cursortab.nvim",
	-- version = "*", -- Use latest tagged version for more stability
	lazy = false, -- The server is already lazy loaded
	build = "cd server && go build",
	config = function()
		require("cursortab").setup({
			provider = {
				-- Copilot
				-- type = "copilot",

				-- Zeta-2 (best local)
				type = "zeta-2",
				url = "http://localhost:8000",
				max_tokens = 64,
				model = "zeta-2-mlx-4bit",
				temperature = 0.1,

				-- Qwen3.5-0.8B (fastest local, defaults to "inline")
				-- url = "http://localhost:11434",

				-- sweep-next-edit-0.5B/1.5B (fastest local)
				-- type = "sweep",
				-- url = "http://localhost:8000",
			},
		})
	end,
}
