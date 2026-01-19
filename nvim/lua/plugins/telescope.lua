return {
	-- change telescope config
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			{
				"sangn-classdojo/telescope-fzf-native.nvim",
				build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build",
			}
		},

		opts = function()
			local action_state = require("telescope.actions.state")
			local sorters = require("telescope.sorters")

			return {
				defaults = {
					file_ignore_patterns = { "lib/" },
					mappings = {
						i = {
							['<C-u>'] = false,
							['<C-d>'] = false,
							-- Ctrl-r to toggle fuzzy/exact matching
							["<C-r>"] = function(prompt_bufnr)
								local picker = action_state.get_current_picker(prompt_bufnr)
								local current_sorter = picker.sorter

								if current_sorter.fuzzy == false then
									picker.sorter = sorters.get_fuzzy_file()
									print("Fuzzy matching: ON")
								else
									picker.sorter = sorters.get_generic_fuzzy_sorter({ fuzzy = false })
									print("Fuzzy matching: OFF (exact)")
								end

								picker:refresh(false, { reset_prompt = false })
							end,
						},
					},
				},
			}
		end,

		config = function(_, opts)
			local telescope = require("telescope")
			telescope.setup(opts)
			telescope.load_extension("fzf")
			local actions = require("telescope.actions")
			local action_state = require("telescope.actions.state")

			vim.keymap.set('n', '<leader>?', require('telescope.builtin').oldfiles,
				{ desc = '[?] Find recently opened files' })
			vim.keymap.set('n', '<C-k>', require('telescope.builtin').buffers,
				{ desc = '[ ] Find existing buffers' })
			vim.keymap.set('n', '<leader>fb', require('telescope.builtin').buffers,
				{ desc = '[F]ind [B]uffers' })
			vim.keymap.set('n', '<leader>/', function()
				require('telescope.builtin').current_buffer_fuzzy_find(require('telescope.themes')
					.get_dropdown {
						winblend = 10,
						previewer = false,
					})
			end, { desc = '[/] Fuzzily search in current buffer' })

			vim.keymap.set('n', '<leader>fg', require('telescope.builtin').git_files,
				{ desc = '[F]in[D] Git Files' })
			vim.keymap.set('n', '<leader>fa', require('telescope.builtin').find_files,
				{ desc = '[F]ind [A]ll Files' })
			vim.keymap.set('n', '<leader>sh', require('telescope.builtin').help_tags,
				{ desc = '[S]earch [H]elp' })
			vim.keymap.set('n', '<leader>fw', require('telescope.builtin').grep_string,
				{ desc = '[F]ind current [W]ord' })
			local tb = require("telescope.builtin")

			-- Common toggles used by ripgrep-based pickers.
			local function rg_args_for_toggles(show_tests, only_src)
				local rg_args = {}
				if not show_tests then
					table.insert(rg_args, "--glob")
					table.insert(rg_args, "!*.test.ts")
				end
				if only_src then
					-- Limit results to paths under src/
					table.insert(rg_args, "--glob")
					table.insert(rg_args, "src/**")
				end
				return rg_args
			end

			local function suffix_for_toggles(show_tests, only_src)
				local parts = {}
				if not show_tests then
					table.insert(parts, "no tests")
				end
				if only_src then
					table.insert(parts, "src only")
				end
				if #parts == 0 then
					return ""
				end
				return " (" .. table.concat(parts, ", ") .. ")"
			end

			local function grep_string_with_toggles(search, base_opts)
				local show_tests = true
				local only_src = false

				local function run(current_search)
					tb.grep_string(vim.tbl_deep_extend("force", base_opts or {}, {
						search = current_search,
						word_match = nil,
						prompt_title = "Grep" .. suffix_for_toggles(show_tests, only_src),
						additional_args = function()
							return rg_args_for_toggles(show_tests, only_src)
						end,
						attach_mappings = function(prompt_bufnr, map)
							local function rerun()
								local line = action_state.get_current_line()
								actions.close(prompt_bufnr)
								run(line ~= "" and line or current_search)
							end

							local function toggle_tests()
								show_tests = not show_tests
								rerun()
							end

							local function toggle_only_src()
								only_src = not only_src
								rerun()
							end

							map("i", "<C-t>", toggle_tests)
							map("n", "<C-t>", toggle_tests)
							map("i", "<C-s>", toggle_only_src)
							map("n", "<C-s>", toggle_only_src)
							return true
						end,
					}))
				end

				run(search)
			end

			local function live_grep_with_toggles()
				local show_tests = true
				local only_src = false

				local function run(default_text)
					tb.live_grep({
						default_text = default_text,
						prompt_title = "Live Grep" .. suffix_for_toggles(show_tests, only_src),
						additional_args = function()
							return rg_args_for_toggles(show_tests, only_src)
						end,
						attach_mappings = function(prompt_bufnr, map)
							local function rerun()
								local line = action_state.get_current_line()
								actions.close(prompt_bufnr)
								run(line)
							end

							local function toggle_tests()
								show_tests = not show_tests
								rerun()
							end

							local function toggle_only_src()
								only_src = not only_src
								rerun()
							end

							map("i", "<C-t>", toggle_tests)
							map("n", "<C-t>", toggle_tests)
							map("i", "<C-s>", toggle_only_src)
							map("n", "<C-s>", toggle_only_src)
							return true
						end,
					})
				end

				run("")
			end

			-- Override grep mappings to include toggles inside Telescope.
			vim.keymap.set('n', '<leader>fw', function()
				grep_string_with_toggles(vim.fn.expand("<cword>"))
			end, { desc = '[F]ind current [W]ord (toggle tests/src)' })

			vim.keymap.set('n', '<leader>fg', live_grep_with_toggles,
				{ desc = '[F]ind by [G]rep (toggle tests/src)' })
		vim.keymap.set('n', '<leader>fd', require('telescope.builtin').diagnostics,
			{ desc = '[F]ind [D]iagnostics' })
		
	-- :Ag! command - supports regex and directory search
	-- Usage: :Ag! pattern [directory]
	-- Optional flags:
	--   --ignore-tests   Exclude files matching *.test.ts
	--   --split          Populate quickfix + open bottom split (no Telescope UI)
	--   --all            Include hidden + ignored files (rg: --hidden --no-ignore)
	-- Supports multi-word patterns: :Ag! 'pattern with spaces' src
	vim.api.nvim_create_user_command("Ag", function(opts)
		-- #region agent log
		local function _agent_log(hypothesisId, message, data)
			pcall(function()
				local f = io.open(vim.fn.expand("$DOTFILES/.cursor/debug.log"), "a")
				if not f then
					return
				end
				f:write(vim.json.encode({
					sessionId = "debug-session",
					runId = "pre-fix",
					hypothesisId = hypothesisId,
					location = "nvim/lua/plugins/telescope.lua:Ag",
					message = message,
					data = data,
					timestamp = vim.loop.now(),
				}) .. "\n")
				f:close()
			end)
		end
		-- #endregion

		local ignore_tests = false
		local open_split = false
		local include_all = false
		local include_hidden = false
		local include_no_ignore = false
		local args = {}

		-- Allow lightweight "flags" that are interpreted by this wrapper.
		for _, arg in ipairs(opts.fargs) do
			if arg == "--ignore-tests" then
				ignore_tests = true
			elseif arg == "--split" then
				open_split = true
			elseif arg == "--all" then
				include_all = true
			elseif arg == "--hidden" then
				include_hidden = true
			elseif arg == "--no-ignore" then
				include_no_ignore = true
			else
				table.insert(args, arg)
			end
		end
		local pattern = ""
		local dir = nil
		
		-- Helper function to strip surrounding quotes from a string
		local function strip_quotes(str)
			return str:gsub("^['\"](.*)['\" ]$", "%1")
		end
		
		-- If we have multiple args, check if the last one looks like a directory
		if #args > 1 then
			local last_arg = args[#args]
			-- Check if the last argument is an existing directory or looks like a path
			-- Don't treat it as a dir if it has quotes (it's part of the pattern)
			if not last_arg:match("^['\"]") and (vim.fn.isdirectory(last_arg) == 1 or last_arg:match("[/\\]")) then
				-- Last arg is a directory, everything else is the pattern
				dir = last_arg
				pattern = table.concat(vim.list_slice(args, 1, #args - 1), " ")
			else
				-- No directory specified, join all args as pattern
				pattern = table.concat(args, " ")
			end
		elseif #args == 1 then
			pattern = args[1]
		end
		
		-- Strip quotes from the pattern (both single and double)
		pattern = pattern:gsub("^['\"]", ""):gsub("['\"]$", "")

		_agent_log("A", "Ag invoked (post-flag-parse)", {
			bang = opts.bang,
			open_split = open_split,
			ignore_tests = ignore_tests,
			include_all = include_all,
			include_hidden = include_hidden,
			include_no_ignore = include_no_ignore,
			raw_fargs = opts.fargs,
			args = args,
			pattern = pattern,
			dir = dir,
		})
		
		-- Build ripgrep arguments
		local rg_args = {}
		
		-- :Ag! (bang) searches everything including hidden/ignored files *for Telescope mode*.
		-- For --split we default to respecting ignores (fast/low-memory); use --all to opt in.
		local want_all = include_all or include_hidden or include_no_ignore
		if open_split and opts.bang and not want_all then
			_agent_log("A", "split mode ignoring bang; use --all for ignored/hidden", {})
		end
		if (opts.bang and not open_split) or (open_split and want_all) then
			if include_all or (opts.bang and not open_split) or include_no_ignore then
				table.insert(rg_args, "--no-ignore")
			end
			if include_all or (opts.bang and not open_split) or include_hidden then
				table.insert(rg_args, "--hidden")
			end
		end

		if ignore_tests then
			-- ripgrep: exclude matching files from the search
			table.insert(rg_args, "--glob")
			table.insert(rg_args, "!*.test.ts")
		end

		local function open_quickfix_with_rg()
			local cmd = { "rg", "--vimgrep", "--color=never" }
			vim.list_extend(cmd, rg_args)
			table.insert(cmd, pattern)
			if dir then
				table.insert(cmd, dir)
			end

			local start_ms = vim.loop.now()
			_agent_log("B", "open_quickfix_with_rg start", {
				cmd = cmd,
				has_vim_system = vim.system ~= nil,
				cwd = vim.fn.getcwd(),
				start_ms = start_ms,
			})

			local function set_qf_and_open(lines, exit_code, stderr)
				_agent_log("D", "set_qf_and_open", {
					exit_code = exit_code,
					lines_count = type(lines) == "table" and #lines or -1,
					stderr = (stderr or ""):sub(1, 200),
					duration_ms = vim.loop.now() - start_ms,
					sample_1 = type(lines) == "table" and lines[1] or nil,
					sample_2 = type(lines) == "table" and lines[2] or nil,
				})

				-- Use " " (replace) to ensure lines+efm are parsed into items reliably.
				vim.fn.setqflist({}, " ", {
					title = string.format("Ag%s: %s", opts.bang and "!" or "", dir or vim.fn.getcwd()),
					lines = lines,
					efm = "%f:%l:%c:%m",
				})

				vim.cmd("botright copen")
				_agent_log("D", "after copen", { qf_len = #vim.fn.getqflist() })
				if exit_code == 1 then
					vim.notify("No matches", vim.log.levels.INFO)
				elseif exit_code ~= 0 then
					vim.notify(
						("rg failed (%s): %s"):format(tostring(exit_code), (stderr or ""):gsub("%s+$", "")),
						vim.log.levels.ERROR
					)
				end
			end

			-- rg exit codes: 0 = matches, 1 = no matches, 2 = error
			if vim.system then
				-- Prefer vim.system when available (Neovim 0.10+).
				local ok, spawned_or_err = pcall(function()
					return vim.system(cmd, { text = true }, function(obj)
						vim.schedule(function()
							_agent_log("C", "vim.system callback", {
								code = obj.code,
								stdout_len = #(obj.stdout or ""),
								stderr_len = #(obj.stderr or ""),
								duration_ms = vim.loop.now() - start_ms,
							})
							local lines = vim.split(obj.stdout or "", "\n", { trimempty = true })
							set_qf_and_open(lines, obj.code, obj.stderr)
						end)
					end)
				end)

				if ok then
					_agent_log("C", "vim.system spawned", { spawned = tostring(spawned_or_err) })
					return
				end

				_agent_log("C", "vim.system errored; falling back", { err = tostring(spawned_or_err) })
			end

			-- Fallback for older Neovim: run via systemlist with a shell-escaped command string.
			local parts = {}
			for _, a in ipairs(cmd) do
				table.insert(parts, vim.fn.shellescape(a))
			end
			local cmd_str = table.concat(parts, " ")
			_agent_log("C", "fallback systemlist", { cmd_str = cmd_str })
			local lines = vim.fn.systemlist(cmd_str)
			local exit_code = vim.v.shell_error
			set_qf_and_open(lines, exit_code, "")
		end

		-- Use grep_string for literal search that executes immediately
		-- This is better for the Ag use case where you want instant results
		if open_split then
			open_quickfix_with_rg()
			return
		end

		tb.grep_string({
			search = pattern,
			search_dirs = dir and { dir } or nil,
			word_match = nil,  -- Don't require word boundaries
			prompt_title = string.format("Ag%s: %s", opts.bang and "!" or "", dir or vim.fn.getcwd()),
			additional_args = function() 
				return rg_args
			end,
		})
	end, { nargs = "*", bang = true, complete = "dir" })

		-- \aw - instantly search for word under cursor using grep_string (much faster)
		vim.keymap.set("n", "<leader>aw", function()
			grep_string_with_toggles(vim.fn.expand("<cword>"))
		end, { desc = "Find word under cursor" })
	end,
	},
}
