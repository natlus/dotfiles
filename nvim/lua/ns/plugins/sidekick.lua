return {
	"folke/sidekick.nvim",
	opts = {
		nes = {
			enabled = true,
			trigger = {
				events = { "ModeChanged i:n", "TextChanged", "User SidekickNesDone" },
			},
		},
		cli = {
			enabled = false,
			mux = {
				backend = "zellij",
				split = {
					vertical = true,
					size = 0.25,
				},
				enabled = true,
			},
			win = {
				layout = "left",
				split = {
					width = 50,
					height = 0,
				},
			},
		},
	},
	keys = {
		{
			"<M-Tab>",
			function()
				-- if there is a next edit, jump to it, otherwise apply it if any
				if not require("sidekick").nes_jump_or_apply() then
					return "<M-Tab>"
				end
			end,
			mode = { "i", "n" },
			expr = true,
			desc = "Goto/Apply Next Edit Suggestion",
		},
	},
}
