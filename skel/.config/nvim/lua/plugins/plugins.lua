vim.api.nvim_set_var('vim_markdown_frontmatter', 1)

return {

  -- ── Mason (LSP/DAP/formatter installer) ─────────────────────────────────
  {
    'mason-org/mason.nvim',
    opts = {
      ensure_installed = {
        'mypy', 'pyright', 'debugpy',
        'black', 'isort',
        'clang-format', 'clangd',
        'shfmt', 'stylua',
      },
    },
  },

  -- ── LSP ─────────────────────────────────────────────────────────────────
  {
    'neovim/nvim-lspconfig',
    opts = {
      autoformat    = true,
      inlay_hints   = { enabled = false },
      servers = {
        pyright = {
          enabled = vim.g.lazyvim_python_lsp == 'pyright' or vim.g.lazyvim_python_lsp == nil,
        },
        clangd = {
          keys = {
            { '<leader>cR', '<cmd>ClangdSwitchSourceHeader<cr>', desc = 'Switch Source/Header' },
          },
          root_dir = function(bufnr, on_dir)
            local fname = vim.api.nvim_buf_get_name(bufnr)
            local root = require('lspconfig.util').root_pattern(
              'compile_commands.json', 'compile_flags.txt', 'configure.ac', '.git'
            )(fname) or vim.fs.dirname(fname)
            on_dir(root)
          end,
          capabilities = {
            offsetEncoding = { 'utf-16' },
          },
          cmd = {
            'clangd',
            '--background-index',
            '--clang-tidy',
            '--header-insertion=iwyu',
            '--completion-style=detailed',
            '--function-arg-placeholders',
            '--fallback-style=llvm',
          },
          init_options = {
            usePlaceholders    = true,
            completeUnimported = true,
            clangdFileStatus   = true,
          },
        },
      },
    },
  },

  -- ── Git signs ────────────────────────────────────────────────────────────
  {
    'lewis6991/gitsigns.nvim',
    config = function()
      require('gitsigns').setup({
        signs = {
          add          = { text = '│' },
          change       = { text = '│' },
          delete       = { text = '_' },
          topdelete    = { text = '‾' },
          changedelete = { text = '~' },
          untracked    = { text = '┆' },
        },
        signcolumn             = true,
        numhl                  = false,
        linehl                 = false,
        word_diff              = false,
        watch_gitdir           = { interval = 1000, follow_files = true },
        attach_to_untracked    = true,
        current_line_blame     = false,
        current_line_blame_opts = {
          virt_text     = true,
          virt_text_pos = 'eol',
          delay         = 1000,
          ignore_whitespace = false,
        },
        current_line_blame_formatter = '<author>, <author_time:%Y-%m-%d> - <summary>',
        sign_priority   = 6,
        update_debounce = 100,
        status_formatter = nil,
        max_file_length  = 40000,
        preview_config   = { border = 'single', style = 'minimal', relative = 'cursor', row = 0, col = 1 },
      })
    end,
  },

  -- ── which-key ────────────────────────────────────────────────────────────
  { 'folke/which-key.nvim' },

  -- ── DAP (debugger) ───────────────────────────────────────────────────────
  { 'nvim-neotest/neotest-python' },
  { 'nvim-neotest/nvim-nio' },

  {
    'mfussenegger/nvim-dap-python',
    config = function()
      local path = require('mason-registry').get_package('debugpy'):get_install_path()
      require('dap-python').setup(path .. '/venv/bin/python')
    end,
  },

  {
    'mfussenegger/nvim-dap',
    optional = true,
    event    = 'VeryLazy',
    config   = function()
      local dap = require('dap')
      dap.adapters.gdb = {
        type    = 'executable',
        command = vim.fn.exepath('gdb'),
        args    = { '-i', 'dap' },
      }
      dap.configurations.c = {
        {
          name    = 'Launch file',
          type    = 'gdb',
          request = 'launch',
          program = function()
            return vim.fn.input('Executable: ', vim.fn.getcwd() .. '/', 'file')
          end,
          cwd = '${workspaceFolder}',
        },
      }
    end,
  },

  {
    'rcarriga/nvim-dap-ui',
    dependencies = { 'mfussenegger/nvim-dap', 'nvim-neotest/nvim-nio' },
    opts = function()
      local dap, dapui = require('dap'), require('dapui')
      dap.listeners.before.attach.dapui_config          = function() dapui.open() end
      dap.listeners.before.launch.dapui_config          = function() dapui.open() end
      dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
      dap.listeners.before.event_exited.dapui_config    = function() dapui.close() end
      return {
        enabled                    = true,
        enabled_commands           = true,
        highlight_changed_variables = true,
        highlight_new_as_changed   = false,
        show_stop_reason           = true,
        commented                  = false,
        only_first_definition      = true,
        all_references             = false,
        filter_references_pattern  = '<module',
        virt_text_pos              = 'eol',
        all_frames                 = false,
        virt_lines                 = false,
        virt_text_win_col          = nil,
      }
    end,
  },

  { 'theHamsta/nvim-dap-virtual-text', opts = {} },

  -- ── Formatting (conform.nvim) ─────────────────────────────────────────────
  {
    'stevearc/conform.nvim',
    keys = {
      {
        '<leader>mp',
        function()
          require('conform').format({ lsp_fallback = true, async = false, timeout_ms = 500 })
        end,
        mode = { 'n', 'v' },
        desc = 'Format file or range',
      },
    },
    init = function()
      vim.api.nvim_create_user_command('Format', function(args)
        local range = nil
        if args.count ~= -1 then
          local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
          range = { start = { args.line1, 0 }, ['end'] = { args.line2, end_line:len() } }
        end
        require('conform').format({ async = true, lsp_fallback = true, range = range })
      end, { range = true })
    end,
    opts = {
      formatters_by_ft = {
        python = { 'isort', 'black', 'autopep8' },
        cpp    = { 'clang_format' },
        c      = { 'clang_format' },
      },
    },
  },

  -- ── Live server (HTML/JS) ─────────────────────────────────────────────────
  {
    'barrett-ruth/live-server.nvim',
    build = 'pnpm add -g live-server',
    cmd   = { 'LiveServerStart', 'LiveServerStop' },
    opts  = { args = { '--port=8080', '--browser=firefox' } },
  },

  -- ── Bufferline ────────────────────────────────────────────────────────────
  {
    'akinsho/bufferline.nvim',
    version      = '*',
    branch       = 'main',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
  },

  -- ── Icons ─────────────────────────────────────────────────────────────────
  { 'nvim-tree/nvim-web-devicons', lazy = true },

  -- ── Telescope ────────────────────────────────────────────────────────────
  {
    'nvim-telescope/telescope.nvim',
    keys = {
      {
        '<leader>fp',
        function()
          require('telescope.builtin').find_files({ cwd = require('lazy.core.config').options.root })
        end,
        desc = 'Find Plugin File',
      },
    },
    opts = {
      defaults = {
        layout_strategy = 'horizontal',
        layout_config   = { prompt_position = 'top' },
        sorting_strategy = 'ascending',
        winblend        = 0,
      },
    },
  },

  {
    'telescope.nvim',
    dependencies = {
      'nvim-telescope/telescope-fzf-native.nvim',
      build  = 'make',
      config = function() require('telescope').load_extension('fzf') end,
    },
  },

  -- ── mini.surround ─────────────────────────────────────────────────────────
  { 'nvim-mini/mini.surround' },

  -- ── Treesitter ────────────────────────────────────────────────────────────
  {
    'nvim-treesitter/nvim-treesitter',
    opts = {
      ensure_installed = {
        'bash', 'c', 'diff', 'html', 'javascript', 'jsdoc',
        'json', 'jsonc', 'lua', 'luadoc', 'luap', 'markdown',
        'markdown_inline', 'printf', 'python', 'query', 'regex',
        'toml', 'tsx', 'typescript', 'vim', 'vimdoc', 'xml', 'yaml',
      },
    },
  },

  -- ── noice.nvim — keep classic cmdline, disable popup replacements ─────────
  {
    'folke/noice.nvim',
    opts = {
      cmdline   = { enabled = false },
      messages  = { enabled = false },
      popupmenu = { enabled = false },
    },
  },

  -- ── Statusline ────────────────────────────────────────────────────────────
  { 'nvim-lualine/lualine.nvim' },

  -- ── Floating terminal ─────────────────────────────────────────────────────
  { 'voldikss/vim-floaterm' },

  -- ── Breadcrumb (barbecue + navic) ─────────────────────────────────────────
  {
    'utilyre/barbecue.nvim',
    name         = 'barbecue',
    version      = '*',
    dependencies = { 'SmiteshP/nvim-navic', 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('barbecue').setup()
      require('barbecue.ui').toggle(true)
    end,
  },

  -- ── Twilight (dim inactive code) ──────────────────────────────────────────
  {
    'folke/twilight.nvim',
    opts = {
      dimming = {
        alpha    = 0.25,
        color    = { 'Normal', '#ffffff' },
        term_bg  = '#000000',
        inactive = false,
      },
      context    = 1,
      treesitter = true,
      expand     = { 'function', 'method', 'table', 'if_statement' },
      exclude    = {},
    },
  },

}
