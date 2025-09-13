return {
     -- Set lualine as statusline
     'nvim-lualine/lualine.nvim',
     -- See `:help lualine.txt`
     opts = {
       options = {
         icons_enabled = true,
         theme = 'catppuccin-mocha',
         component_separators = '|',
         section_separators = '',
       },
       sections = {
         lualine_a = {'mode'},
         lualine_b = {'branch', 'diff', 'diagnostics'},
         lualine_c = {
           {
             'filename',
             path = 1, -- 0 = just filename, 1 = relative path, 2 = absolute path
             shorting_target = 40, -- Shortens path to leave 40 spaces in the window
           }
         },
         lualine_x = {'encoding', 'fileformat', 'filetype'},
         lualine_y = {'progress'},
         lualine_z = {'location'}
       },
       inactive_sections = {
         lualine_a = {},
         lualine_b = {},
         lualine_c = {
           {
             'filename',
             path = 1, -- Show relative path in inactive windows too
           }
         },
         lualine_x = {'location'},
         lualine_y = {},
         lualine_z = {}
       },
     },
}
