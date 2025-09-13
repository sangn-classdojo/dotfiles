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

			vim.keymap.set('n', '<leader>?', require('telescope.builtin').oldfiles,
				{ desc = '[?] Find recently opened files' })
			vim.keymap.set('n', '<C-k>', require('telescope.builtin').buffers,
				{ desc = '[ ] Find existing buffers' })
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
			vim.keymap.set('n', '<leader>fg', require('telescope.builtin').live_grep,
				{ desc = '[F]ind by [G]rep' })
		vim.keymap.set('n', '<leader>fd', require('telescope.builtin').diagnostics,
			{ desc = '[F]ind [D]iagnostics' })
		local tb = require("telescope.builtin")
		
		-- :Ag! command - supports regex and directory search
		vim.api.nvim_create_user_command("Ag", function(opts)
			local args = opts.fargs
			local pattern = args[1] or ""
			local dir = args[2]

			-- Build ripgrep arguments
			local rg_args = {}
			
			-- :Ag! searches everything including hidden/ignored files
			if opts.bang then
				table.insert(rg_args, "--no-ignore")
				table.insert(rg_args, "--hidden")
			end

			-- Enable PCRE2 regex support for more complex patterns
			table.insert(rg_args, "--pcre2")
			
			-- If pattern contains word boundaries or other regex, use it as-is
			-- Otherwise ripgrep will handle it naturally

			tb.live_grep({
				default_text = pattern,
				search_dirs = dir and { dir } or nil,
				additional_args = function() 
					return rg_args
				end,
			})
		end, { nargs = "*", bang = true, complete = "dir" })

		-- \aw - populate :Ag! command but don't execute (let user hit enter)
		vim.keymap.set("n", "<leader>aw", function()
			-- Get word under cursor
			local word = vim.fn.expand("<cword>")
			-- Pre-populate command line with :Ag! and the word, but don't execute
			vim.fn.feedkeys(":Ag! " .. word, "n")
		end, { desc = "Populate :Ag! with word under cursor" })
	end,
	},
}
