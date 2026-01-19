vim.keymap.set("n", "<leader>nt", "<cmd>Neotree toggle<cr>", { desc = "Toggle Neo-tree" })
-- print("keymaps: start")
vim.keymap.set('n', ';', ':', { noremap = true })
-- Remove this line - it blocks leader key mappings
-- vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

vim.keymap.set('n', '<C-l>', ":bnext<CR>", { silent = true })
vim.keymap.set('n', '<C-h>', ":bprevious<CR>", { silent = true })

vim.cmd([[
cnoreabbrev W w
cnoreabbrev Wq wq
cnoreabbrev WQ wq
cnoreabbrev Q! q!
cnoreabbrev Today ObsidianToday
nnoremap <leader>m :!yarn run mocha %<CR>
]])

local errors = vim.diagnostic.get(0, {
	severity = vim.diagnostic.severity.ERROR,
})

-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous diagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next diagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
-- vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })
vim.keymap.set('n', '<leader>q', function()
	vim.diagnostic.setloclist({ severity = vim.diagnostic.severity.ERROR })
end, { desc = 'Open diagnostics list (errors only)' })

-- print("keymaps: done")
--

-- Leader + ff = fuzzy find files
vim.keymap.set("n", "<leader>ff", function()
	require("telescope.builtin").find_files()
end, { desc = "Find Files" })

-- If you want delete-without-copy, use leader+d instead:
vim.keymap.set("n", "<leader>d", '"_d', { desc = "Delete without copying" })
vim.keymap.set("v", "<leader>d", '"_d', { desc = "Delete without copying" })
-- Avoid conflict with <leader>cp by not using <leader>c as a normal-mode operator prefix
vim.keymap.set("n", "<leader>cc", '"_c', { desc = "Change without copying (operator)" })
vim.keymap.set("v", "<leader>c", '"_c', { desc = "Change without copying" })

-- Create a new tab
vim.keymap.set("n", "<leader><CR>", ":tabnew<CR>", { desc = "New Tab" })

-- Previous tab
vim.keymap.set("n", "<leader>[", ":tabprevious<CR>", { desc = "Previous Tab" })

-- Next tab
vim.keymap.set("n", "<leader>]", ":tabnext<CR>", { desc = "Next Tab" })

-- Function to generate GitHub link with current commit SHA and line numbers
local function get_github_link()
	-- Get git root directory
	local git_root = vim.fn.system("git rev-parse --show-toplevel"):gsub("\n", "")
	if vim.v.shell_error ~= 0 then
		print("Not in a git repository")
		return
	end

	-- Get current commit SHA
	local commit_sha = vim.fn.system("git rev-parse HEAD"):gsub("\n", "")
	if vim.v.shell_error ~= 0 then
		print("Failed to get commit SHA")
		return
	end

	-- Get remote URL and convert to GitHub URL
	local remote_url = vim.fn.system("git config --get remote.origin.url"):gsub("\n", "")
	if vim.v.shell_error ~= 0 then
		print("Failed to get remote URL")
		return
	end

	-- Convert SSH/HTTPS remote to GitHub web URL
	local github_url = remote_url
	-- Handle SSH format: git@github.com:user/repo.git
	github_url = github_url:gsub("git@github%.com:", "https://github.com/")
	-- Handle HTTPS format and remove .git suffix
	github_url = github_url:gsub("%.git$", "")
	
	-- Get current file path relative to git root
	local current_file = vim.fn.expand("%:p")
	-- Ensure git_root doesn't have trailing slash
	git_root = git_root:gsub("/$", "")
	-- Make relative path by removing git_root prefix
	local relative_path = current_file
	if current_file:sub(1, #git_root) == git_root then
		relative_path = current_file:sub(#git_root + 2) -- +2 to skip the root and the slash
	end
	
	-- Get line numbers - handle visual mode properly
	local start_line, end_line
	local mode = vim.api.nvim_get_mode().mode
	
	if mode:match('[vV\22]') then -- Visual, Visual-Line, or Visual-Block mode
		-- We're currently in visual mode - get selection bounds
		local cursor_pos = vim.api.nvim_win_get_cursor(0)
		local visual_start = vim.fn.getpos('v')
		
		start_line = math.min(cursor_pos[1], visual_start[2])
		end_line = math.max(cursor_pos[1], visual_start[2])
		
		print("Visual mode detected - lines: " .. start_line .. " to " .. end_line)
	else
		-- Not in visual mode - always use current cursor line
		start_line = vim.fn.line(".")
		end_line = start_line
		print("Normal mode - using current line: " .. start_line)
	end
	
	-- Fallback if we still get 0
	if start_line == 0 then
		start_line = vim.api.nvim_win_get_cursor(0)[1]
		end_line = start_line
	end
	
	-- Build GitHub URL
	local line_fragment
	if start_line == end_line then
		line_fragment = "#L" .. start_line
	else
		line_fragment = "#L" .. start_line .. "-L" .. end_line
	end
	
	local full_url = github_url .. "/blob/" .. commit_sha .. "/" .. relative_path .. line_fragment
	
	-- Copy to system clipboard
	vim.fn.setreg('+', full_url)
	print("GitHub link copied to clipboard: " .. full_url)
	print("Line(s): " .. start_line .. (start_line ~= end_line and "-" .. end_line or ""))
end

-- Keymaps for GitHub link generation
vim.keymap.set("n", "<leader>gl", get_github_link, { desc = "Copy GitHub link to current line" })
vim.keymap.set("v", "<leader>gl", get_github_link, { desc = "Copy GitHub link to selected lines" })

-- Function to copy relative file path to clipboard
local function copy_relative_path()
	-- Get git root directory (project root)
	local git_root = vim.fn.system("git rev-parse --show-toplevel"):gsub("\n", "")
	if vim.v.shell_error ~= 0 then
		print("Not in a git repository")
		return
	end

	-- Get current file path
	local current_file = vim.fn.expand("%:p")
	
	-- Calculate relative path
	local relative_path = current_file:gsub(git_root .. "/", "")
	
	-- Copy to system clipboard
	vim.fn.setreg('+', relative_path)
	print("Copied to clipboard: " .. relative_path)
end

-- Keymap to copy relative file path
-- Map both <leader>cp and <leader>p for fast tapping reliability
vim.keymap.set("n", "<leader>cp", copy_relative_path, { desc = "Copy relative file path" })
vim.keymap.set("n", "<leader>p", copy_relative_path, { desc = "Copy relative file path" })

-- Test keymaps are now centralized in vim-test.lua plugin

-- Dark mode toggle function
local function toggle_dark_mode()
	-- Run the toggle script
	local result = vim.fn.system("$DOTFILES/bin/toggle-terminal-dark-mode.sh")
	
	-- Check if script ran successfully
	if vim.v.shell_error == 0 then
		-- Reload the colorscheme to reflect changes immediately
		vim.cmd("source ~/.config/nvim/lua/plugins/color.lua")
		
		-- Check which theme is now active by reading the color.lua file
		local color_file = io.open(vim.fn.expand("~/.config/nvim/lua/plugins/color.lua"), "r")
		if color_file then
			local content = color_file:read("*all")
			color_file:close()
			
			if string.match(content, "catppuccin%-mocha") then
				print("Switched to dark mode (catppuccin-mocha)")
			elseif string.match(content, "catppuccin%-latte") then
				print("Switched to light mode (catppuccin-latte)")
			else
				print("Theme toggled")
			end
		else
			print("Theme toggled successfully")
		end
	else
		print("Error running toggle script: " .. result)
	end
end

-- Keybinding to toggle dark mode
vim.keymap.set("n", "<leader>td", toggle_dark_mode, { desc = "Toggle Dark Mode" })

-- Custom folding keymap (built-in fold commands work automatically)
vim.keymap.set("n", "<leader>zz", "zMzv", { desc = "Close all folds except current" })

