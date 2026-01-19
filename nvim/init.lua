vim.g.mapleader = "\\"

-- Custom fold text function - define early to ensure availability
function _G.custom_foldtext()
    -- Get fold info - these are only available when actually folding
    local foldstart = vim.v.foldstart or 0
    local foldend = vim.v.foldend or 0
    
    -- If we're not in a proper fold context, return default
    if foldstart == 0 or foldend == 0 or foldstart > foldend then
        return "+"
    end
    
    local line_count = foldend - foldstart + 1
    
    -- Get the first line of the fold
    local first_line = vim.fn.getline(foldstart)
    if not first_line or first_line == "" then 
        return "+ [" .. line_count .. " lines] (empty)"
    end
    
    -- Clean up the line (remove leading whitespace)  
    local cleaned_line = first_line:gsub("^%s*", "")
    if cleaned_line == "" then
        return "+ [" .. line_count .. " lines] (whitespace)"
    end
    
    -- Start with the cleaned line as preview
    local preview = cleaned_line
    
    -- For test files, try to extract just the description
    if cleaned_line:match("^it%s*%(") or cleaned_line:match("^describe%s*%(") then
        -- Try to extract the string inside quotes
        local desc = cleaned_line:match('it%s*%(%s*["\']([^"\']+)["\']') or
                    cleaned_line:match('describe%s*%(%s*["\']([^"\']+)["\']')
        
        if desc and desc ~= "" then
            local test_type = cleaned_line:match("^(%w+)") or "test"
            preview = test_type .. "(\"" .. desc .. "\")"
        end
    end
    
    -- Truncate if too long  
    local max_width = vim.api.nvim_win_get_width(0) - 25
    if max_width > 20 and #preview > max_width then
        preview = preview:sub(1, max_width - 3) .. "..."
    end
    
    return "+ [" .. line_count .. " lines] " .. preview
end

require('config.options');
require('config.keymaps');
require('config.autocmds');
require('config.lazy');
