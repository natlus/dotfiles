return {
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
}
