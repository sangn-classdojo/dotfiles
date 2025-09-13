return {
	"vim-test/vim-test",
	dependencies = {
		"preservim/vimux", -- <-- add this
	},
	config = function()
		-- Strategy for running tests (neovim = output in a split, tmux = uses tmux pane)
		vim.g["test#strategy"] = "vimux"

		-- Tell vim-test to use yarn mocha for JavaScript
		vim.g["test#javascript#mocha#executable"] = "yarn mocha"

		-- Keymaps
		local map = function(lhs, rhs, desc)
			vim.keymap.set("n", lhs, rhs, { silent = true, desc = desc })
		end

		map("<leader>rn", ":TestNearest<CR>", "Test: Run Nearest")
		map("<leader>rl", ":TestLast<CR>", "Test: Run Last")
		map("<leader>tf", ":TestFile<CR>", "Test: File")
		map("<leader>ts", ":TestSuite<CR>", "Test: Suite")
	end,
}
