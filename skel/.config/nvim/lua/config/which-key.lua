-- which-key.nvim — leader key menu
-- Uses the v3 API: which_key.add() with flat list format.

vim.g.mapleader = ' '

local status_ok, which_key = pcall(require, 'which-key')
if not status_ok then return end

which_key.setup({
  icons     = { breadcrumb = '»', separator = '➜', group = '+' },
  win       = { border = 'rounded' },
  show_help = true,
})

which_key.add({
  { '<leader>W',  '<cmd>w!<CR>',                                       desc = 'Save' },
  { '<leader>a',  '<cmd>Alpha<cr>',                                    desc = 'Alpha' },
  { '<leader>e',  '<cmd>Neotree<cr>',                                  desc = 'Neotree' },
  { '<leader>k',  '<cmd>bdelete<CR>',                                  desc = 'Kill Buffer' },
  { '<leader>m',  '<cmd>Mason<cr>',                                    desc = 'Mason' },
  { '<leader>r',  '<cmd>lua vim.lsp.buf.format{async=true}<cr>',       desc = 'Reformat Code' },

  { '<leader>l',  group = 'LSP' },
  { '<leader>li', '<cmd>LspInfo<cr>',                                  desc = 'Info' },
  { '<leader>lr', '<cmd>lua vim.lsp.buf.rename()<cr>',                 desc = 'Rename' },
  { '<leader>ls', '<cmd>Telescope lsp_document_symbols<cr>',           desc = 'Document Symbols' },
  { '<leader>lS', '<cmd>Telescope lsp_dynamic_workspace_symbols<cr>',  desc = 'Workspace Symbols' },

  { '<leader>f',  group = 'File Search' },
  { '<leader>fc', '<cmd>Telescope colorscheme<cr>',                    desc = 'Colorscheme' },
  { '<leader>ff', "<cmd>lua require('telescope.builtin').find_files()<cr>", desc = 'Find files' },
  { '<leader>ft', '<cmd>Telescope live_grep<cr>',                      desc = 'Find Text Pattern' },
  { '<leader>fr', '<cmd>Telescope oldfiles<cr>',                       desc = 'Recent Files' },

  { '<leader>s',  group = 'Search' },
  { '<leader>sh', '<cmd>Telescope help_tags<cr>',                      desc = 'Find Help' },
  { '<leader>sm', '<cmd>Telescope man_pages<cr>',                      desc = 'Man Pages' },
  { '<leader>sr', '<cmd>Telescope registers<cr>',                      desc = 'Registers' },
  { '<leader>sk', '<cmd>Telescope keymaps<cr>',                        desc = 'Keymaps' },
  { '<leader>sc', '<cmd>Telescope commands<cr>',                       desc = 'Commands' },
})
