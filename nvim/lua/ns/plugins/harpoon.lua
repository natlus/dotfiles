return {
	"ThePrimeagen/harpoon",
	branch = "harpoon2",
	dependencies = { "nvim-lua/plenary.nvim" },
	config = function()
		local harpoon = require("harpoon")
		harpoon:setup({})

		local function toggle_snacks_picker(harpoon_files)
			local items = {}
			for idx, item in ipairs(harpoon_files.items) do
				table.insert(items, {
					idx = idx,
					file = item.value,
					text = item.value,
				})
			end

			Snacks.picker({
				title = "Harpoon",
				items = items,
				format = function(item)
					return { { item.idx .. ": ", "SnacksPickerIdx" }, { item.file } }
				end,
				confirm = function(picker, item)
					picker:close()
					if item then
						harpoon_files:select(item.idx)
					end
				end,
				actions = {
					delete = function(picker, item)
						if item then
							table.remove(harpoon_files.items, item.idx)
							if harpoon_files.save then
								harpoon_files:save()
							end
						end
						picker:close()
						toggle_snacks_picker(harpoon_files)
					end,
				},
				win = {
					input = {
						keys = {
							["dd"] = { "delete", mode = { "n" } },
							["<C-d>"] = { "delete", mode = { "n", "i" } },
						},
					},
				},
			})
		end

		vim.keymap.set("n", "<leader>e", function()
			toggle_snacks_picker(harpoon:list())
		end, { desc = "Open harpoon window" })

		vim.keymap.set("n", "<leader>a", function()
			harpoon:list():add()
		end)

		vim.keymap.set("n", "<leader>1", function()
			harpoon:list():select(1)
		end)
		vim.keymap.set("n", "<leader>2", function()
			harpoon:list():select(2)
		end)
		vim.keymap.set("n", "<leader>3", function()
			harpoon:list():select(3)
		end)
		vim.keymap.set("n", "<leader>4", function()
			harpoon:list():select(4)
		end)

		vim.keymap.set("n", "<C-P>", function()
			harpoon:list():prev()
		end)
		vim.keymap.set("n", "<C-N>", function()
			harpoon:list():next()
		end)
	end,
}
