return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons", -- optional
		"MunifTanjim/nui.nvim",
	},
	config = function()
		require("neo-tree").setup({
			close_if_last_window = true,
			window = {
				width = 30,
				mappings = {
					["<space>"] = "toggle_node",
					["l"] = "open",
					["h"] = "close_node",
				},
			},
			filesystem = {
				filtered_items = {
					visible = true, -- Show hidden files
					hide_dotfiles = false,
					hide_gitignored = false,
				},
			},
		})

		-- Keymap
		vim.keymap.set("n", "<leader>nt", "<cmd>Neotree toggle<cr>", { desc = "Toggle Neo-tree" })
		vim.keymap.set("n", "<leader>nf", "<Cmd>Neotree reveal<CR>", { desc = "Neo-tree: reveal current file" })
	end,
}
