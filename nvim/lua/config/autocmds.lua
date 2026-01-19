vim.api.nvim_create_autocmd('TextYankPost', {
	callback = function()
		vim.highlight.on_yank()
	end,
	group = vim.api.nvim_create_augroup('YankHighlight', { clear = true }),
	pattern = '*',
})

vim.api.nvim_create_autocmd("BufWritePost", {
	callback = function()
		local diagnostics = vim.diagnostic.get(0, {
			severity = vim.diagnostic.severity.ERROR,
		})
		local items = vim.diagnostic.toqflist(diagnostics)

		-- Always update the location list
		vim.fn.setloclist(0, {}, ' ', {
			title = 'Errors',
			items = items,
		})

		-- Open or close the location list based on presence of errors
		if #items > 0 then
			vim.cmd('lopen')
		else
			vim.cmd('lclose')
		end
	end,
})

-- Custom command to delete all swap files
vim.api.nvim_create_user_command('DeleteSwapFiles', function(opts)
	local scope = opts.args ~= "" and opts.args or "."
	local patterns = { ".*.sw[pon]", "*.swp", "*.swo", "*.swn" }
	local deleted = {}
	
	for _, pattern in ipairs(patterns) do
		local cmd = string.format("find %s -name '%s' -type f 2>/dev/null", scope, pattern)
		local handle = io.popen(cmd)
		if handle then
			for file in handle:lines() do
				local success = os.remove(file)
				if success then
					table.insert(deleted, file)
				end
			end
			handle:close()
		end
	end
	
	if #deleted > 0 then
		print(string.format("Deleted %d swap file(s):", #deleted))
		for _, file in ipairs(deleted) do
			print("  " .. file)
		end
	else
		print("No swap files found in " .. scope)
	end
end, {
	nargs = '?',
	desc = 'Delete all swap files (optionally specify directory, default: current)',
})
