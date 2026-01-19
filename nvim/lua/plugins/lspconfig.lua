return {
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    dependencies = {
      {
        "williamboman/mason-lspconfig.nvim",
        -- NOTE: this is here because mason-lspconfig must install servers prior to running nvim-lspconfig
        lazy = false,
        dependencies = {
          {
            -- NOTE: this is here because mason.setup must run prior to running nvim-lspconfig
            -- see mason.lua for more settings.
            "williamboman/mason.nvim",
            lazy = false,
          },
        },
      },
      {
        "hrsh7th/nvim-cmp",
        lazy = false,
        -- NOTE: this is here because we get the default client capabilities from cmp_nvim_lsp
        -- see cmp.lua for more settings.
      },
      {
        "artemave/workspace-diagnostics.nvim",
        enabled = false,
      },
      -- Useful status updates for LSP.
      -- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
      {
        "j-hui/fidget.nvim",
        enabled = true, -- TODO: figure out how this status shows without fidget
        opts = {},
      },
    },
    config = function()
      -- Ensure a safe, user-writable TMPDIR for LSPs (avoid macOS per-user $TMPDIR issues)
      local safe_tmpdir = "/tmp"
      if vim.fn.isdirectory(safe_tmpdir) == 0 then
        pcall(vim.fn.mkdir, safe_tmpdir, "p")
      end
      local servers = {
        -- denols = {
        --   root_dir = function(fname)
        --     return require('lspconfig.util').root_pattern('deno.json', 'deno.jsonc')(fname)
        --   end,
        --   single_file_support = false,
        -- },
        clangd = {
          cmd = {
            "clangd",
            "--background-index",
            "--clang-tidy",
            "--header-insertion=iwyu",
            "--completion-style=detailed",
            "--function-arg-placeholders",
            "--fallback-style=llvm",
          },
          init_options = {
            usePlaceholders = true,
            completeUnimported = true,
            clangdFileStatus = true,
          },
        },
        eslint = {
          settings = {
            format = { enable = true },
          },
        },
        ts_ls = {
          cmd_env = { TMPDIR = safe_tmpdir, TMP = safe_tmpdir, TEMP = safe_tmpdir },
        },
        lua_ls = {
          settings = {
            Lua = {
              format = {
                enable = true,
              },
            },
          },
        },
      }

      -- TODO: extend config with inspiration from
      -- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/plugins/lsp/init.lua

      require("utils.diagnostics").setup_diagnostics()

      -- LSP servers and clients are able to communicate to each other what features they support.
      -- By default, Neovim doesn't support everything that is in the LSP Specification.
      -- When you add nvim-cmp, luasnip, etc. Neovim now has *more* capabilities.
      -- So, we create new capabilities with nvim cmp, and then broadcast that to the servers.
      local client_capabilities = vim.lsp.protocol.make_client_capabilities()
      -- The nvim-cmp almost supports LSP's capabilities so you should advertise it to LSP servers..
      local completion_capabilities = require("cmp_nvim_lsp").default_capabilities()
      local capabilities = vim.tbl_deep_extend("force", client_capabilities, completion_capabilities)

      local function lsp_references_telescope_with_test_toggle()
        local pickers = require("telescope.pickers")
        local finders = require("telescope.finders")
        local conf = require("telescope.config").values
        local make_entry = require("telescope.make_entry")
        local actions_state = require("telescope.actions.state")

        local bufnr = vim.api.nvim_get_current_buf()
        local clients = vim.lsp.get_clients({ bufnr = bufnr })
        if #clients == 0 then
          vim.notify("No LSP clients attached", vim.log.levels.WARN)
          return
        end

        local encoding = clients[1].offset_encoding or "utf-16"
        local params = vim.lsp.util.make_position_params(0, encoding)
        params.context = { includeDeclaration = true }

        vim.lsp.buf_request_all(bufnr, "textDocument/references", params, function(responses)
          local locations = {}
          for _, resp in pairs(responses) do
            if resp.result and type(resp.result) == "table" then
              vim.list_extend(locations, resp.result)
            end
          end

          local function location_fname(loc)
            local uri = loc.uri or loc.targetUri
            if not uri then
              return nil
            end
            return vim.uri_to_fname(uri)
          end

          local function is_test_location(loc)
            local fname = location_fname(loc)
            return fname ~= nil and fname:match("%.test%.ts$") ~= nil
          end

          local function is_src_location(loc)
            local fname = location_fname(loc)
            if not fname then
              return false
            end
            -- Match ".../src/..." (or Windows path separators).
            return fname:match("[/\\]src[/\\]") ~= nil
          end

          local show_tests = true
          local only_src = false

          local function filtered_locations()
            local out = {}
            for _, loc in ipairs(locations) do
              if (show_tests or not is_test_location(loc)) and (not only_src or is_src_location(loc)) then
                table.insert(out, loc)
              end
            end
            return out
          end

          local function current_items()
            return vim.lsp.util.locations_to_items(filtered_locations(), encoding)
          end

          local function make_finder(opts)
            return finders.new_table({
              results = current_items(),
              entry_maker = make_entry.gen_from_quickfix(opts),
            })
          end

          pickers
            .new({}, {
              prompt_title = "LSP References",
              finder = make_finder({}),
              previewer = conf.qflist_previewer({}),
              sorter = conf.generic_sorter({}),
              attach_mappings = function(prompt_bufnr, map)
                local function toggle_tests()
                  show_tests = not show_tests
                  local picker = actions_state.get_current_picker(prompt_bufnr)
                  picker:refresh(make_finder({}), { reset_prompt = false })
                  vim.notify(
                    show_tests and "References: including tests" or "References: excluding *.test.ts",
                    vim.log.levels.INFO
                  )
                end

                local function toggle_only_src()
                  only_src = not only_src
                  local picker = actions_state.get_current_picker(prompt_bufnr)
                  picker:refresh(make_finder({}), { reset_prompt = false })
                  vim.notify(
                    only_src and "References: only src/" or "References: all paths",
                    vim.log.levels.INFO
                  )
                end

                map("i", "<C-t>", toggle_tests)
                map("n", "<C-t>", toggle_tests)
                map("i", "<C-s>", toggle_only_src)
                map("n", "<C-s>", toggle_only_src)
                return true
              end,
            })
            :find()
        end)
      end

      -- Define on_attach callback at higher scope for better stability
      local function on_attach_callback(client, bufnr)
        local nmap = function(keys, func, desc)
          vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
        end

        -- Use explicit space instead of <leader>
        nmap(' rn', vim.lsp.buf.rename, '[R]e[n]ame')
        nmap(' ca', vim.lsp.buf.code_action, '[C]ode [A]ction')
        nmap('gd', vim.lsp.buf.definition, '[G]oto [D]efinition')
        nmap('gr', lsp_references_telescope_with_test_toggle, '[G]oto [R]eferences')
        nmap('K', vim.lsp.buf.hover, 'Hover Documentation')

        nmap('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
        nmap(' D', vim.lsp.buf.type_definition, 'Type [D]efinition')
        nmap('gI', vim.lsp.buf.implementation, '[G]oto [I]mplementation')
        nmap('L', vim.lsp.buf.signature_help, 'Signature Documentation')
        
        -- Format on save
        vim.api.nvim_create_autocmd('BufWritePre', {
          buffer = bufnr,
          callback = function()
            vim.lsp.buf.format({ async = false })
          end,
        })
      end

      local function setup(server)
        local server_opts = vim.tbl_deep_extend("force", {
          capabilities = vim.deepcopy(capabilities),
          on_attach = on_attach_callback,
        }, servers[server] or {})
        require("lspconfig")[server].setup(server_opts)
      end

      -- Setup servers manually without mason-lspconfig auto-setup
      for server_name, _ in pairs(servers) do
        setup(server_name)
      end

      -- vim.api.nvim_create_autocmd("LspAttach", {
      --   group = vim.api.nvim_create_augroup("lsp-attach-keymaps", { clear = true }),
      --   callback = function(event)
      --     require("config.keymaps").setup_lsp_keymaps(event)
      --   end,
      -- })
    end,
  },
}
-- yanked directly from https://github.com/fredrikaverpil/dotfiles/blob/89b3cdb2f27876e2bae6cb0d2b8be595b6ab2a77/nvim-fredrik/lua/plugins/lsp.lua

-- Example LSP settings below:
-- lua_ls = {
--   cmd = { ... },
--   filetypes = { ... },
--   capabilities = { ... },
--   on_attach = { ... },
--   settings = {
--     Lua = {
--       workspace = {
--         checkThirdParty = false,
--       },
--       codeLens = {
--         enable = true,
--       },
--       completion = {
--         callSnippet = "Replace",
--       },
--     },
--   },
-- },
