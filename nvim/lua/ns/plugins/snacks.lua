return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	---@type snacks.Config
	opts = {
		bigfile = { enabled = true },
		dashboard = { enabled = true },
		explorer = { enabled = true },
		indent = { enabled = true },
		input = { enabled = true },
		picker = {
			enabled = true,
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
}
