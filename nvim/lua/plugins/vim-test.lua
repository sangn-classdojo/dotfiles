return {
	"vim-test/vim-test",
	dependencies = {
		"preservim/vimux", -- <-- add this
	},
	config = function()
		-- Strategy for running tests (neovim = output in a split, tmux = uses tmux pane)
		vim.g["test#strategy"] = "vimux"

		-- Tell vim-test to use pnpm exec mocha for JavaScript, with CA certs
		vim.g["test#javascript#mocha#executable"] = "NODE_EXTRA_CA_CERTS=test/certs/caroot/rootCA.pem pnpm exec mocha"

		-- Keymaps
		local map = function(lhs, rhs, desc)
			vim.keymap.set("n", lhs, rhs, { silent = true, desc = desc })
		end

		-- Override <leader>tn and <leader>tl to run exact mocha command on current file
		-- (bypasses vim-test's ts-node/register)
		-- Helper: run a shell command in Vimux if available, else fallback to terminal
		local function run_in_vimux(cmd)
			if vim.fn.exists(':VimuxRunCommand') == 2 then
				vim.cmd('silent! call VimuxRunCommand(' .. vim.fn.string(cmd) .. ')')
			elseif vim.fn.exists('*VimuxRunCommand') == 1 then
				pcall(vim.fn['VimuxRunCommand'], cmd)
			else
				vim.cmd('botright split | resize 12 | terminal ' .. cmd)
			end
		end

		-- Runner used by <leader>tn and <leader>tl (current-file only)
		local function run_current_file_with_mocha()
			local file = vim.fn.expand("%")
			if file == nil or file == "" then
				print("No file to test")
				return
			end
			local flags = "--no-config --no-opts --exit"
			if file:match("%.ts$") then
				flags = flags .. " -r ts-node/register -r tsconfig-paths/register"
			end
		local cmd = "pnpm exec mocha " .. flags .. " " .. vim.fn.shellescape(file)
		run_in_vimux(cmd)
		end

		-- Override <leader>tf to run exact mocha command on current file via Vimux
		local function run_current_file_with_mocha_tf()
			-- Resolve the current file path relative to the git root if possible
			local abs_file = vim.fn.expand("%:p")
			if abs_file == nil or abs_file == "" then
				print("No file to test")
				return
			end
			local git_root = vim.fn.system("git rev-parse --show-toplevel"):gsub("\n", "")
			local rel_file = abs_file
			if vim.v.shell_error == 0 and git_root ~= nil and git_root ~= "" then
				rel_file = abs_file:gsub(git_root .. "/", "")
			else
				-- fallback to buffer path which may already be relative
				rel_file = vim.fn.expand("%")
			end
	-- Exact command requested for <leader>tf (no extra flags)
	local cmd = "pnpm exec mocha " .. vim.fn.shellescape(rel_file)
	last_custom_test_cmd = cmd
	run_in_vimux(cmd)
	end
		-- Helpers for nearest/last without ts-node/register
		local last_custom_test_cmd = nil
		local function escape_for_js_regex(text)
			-- Escape characters with special meaning in JS regex
			local specials = {
				"(", ")", "[", "]", ".", "+", "-", "*", "?", "^", "$", "|", "{", "}", "\n"
			}
			for _, ch in ipairs(specials) do
				text = text:gsub('%' .. ch, '\\' .. ch)
			end
			return text
		end

		local function get_repo_relative_file()
			local abs_file = vim.fn.expand("%:p")
			local git_root = vim.fn.system("git rev-parse --show-toplevel"):gsub("\n", "")
			if abs_file == nil or abs_file == "" then return nil end
			if vim.v.shell_error == 0 and git_root ~= nil and git_root ~= "" then
				return abs_file:gsub(git_root .. "/", "")
			end
			return vim.fn.expand("%")
		end

		local function find_nearest_test_description()
			local cursor = vim.api.nvim_win_get_cursor(0)
			local row = cursor[1]
			for i = row, 1, -1 do
				local line = vim.fn.getline(i)
				-- Normalize common mocha modifiers
				line = line:gsub('%.%s*only', ''):gsub('%.%s*skip', ''):gsub('%.%s*todo', '')
				-- Try it/test/specify with quoted first arg
				for _, kw in ipairs({ 'it', 'test', 'specify' }) do
					local pat1 = string.format("%%f[%%w]%s%%s*%%(%s*['\"]([^'\"]+)['\"]", kw, '%%')
					local name = line:match(pat1)
					if name and #name > 0 then return name end
				end
			end
			return nil
		end

		local function run_nearest_without_tsnode()
			local rel_file = get_repo_relative_file()
			if not rel_file or rel_file == '' then
				print('No file to test')
				return
			end
			local desc = find_nearest_test_description()
		local cmd
		if desc and #desc > 0 then
			-- Use --fgrep to match literal substring within full Mocha title (includes parent describes)
			cmd = 'pnpm exec mocha ' .. vim.fn.shellescape(rel_file) .. ' --fgrep ' .. vim.fn.shellescape(desc)
		else
				print('No nearby test description found')
				return
			end
			last_custom_test_cmd = cmd
			run_in_vimux(cmd)
		end

		local function run_last_custom()
			if last_custom_test_cmd and #last_custom_test_cmd > 0 then
				run_in_vimux(last_custom_test_cmd)
			else
				print('No last test command to run')
			end
		end

		vim.keymap.set("n", "<leader>tn", run_nearest_without_tsnode, { silent = true, desc = "Test: Run Nearest" })
		vim.keymap.set("n", "<leader>tl", run_last_custom, { silent = true, desc = "Test: Run Last" })
		vim.keymap.set("n", "<leader>tf", run_current_file_with_mocha_tf, { silent = true, desc = "Test: File" })
		map("<leader>ts", ":TestSuite<CR>", "Test: Suite")
	end,
}
