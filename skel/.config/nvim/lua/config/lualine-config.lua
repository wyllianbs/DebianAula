-- Statusline configuration (lualine.nvim)

local icon_filename = require('lualine.components.filename'):extend()
icon_filename.apply_icon = require('lualine.components.filetype').apply_icon

-- Mode block color derived from the active colorscheme's highlight groups.
-- Works with any theme (catppuccin, tokyonight, gruvbox, wbs, etc.)
local mode_colors = {
  n  = 'Function',       -- normal   → Function fg
  i  = 'String',         -- insert   → String fg
  v  = 'Special',        -- visual   → Special fg
  V  = 'Special',
  ['\22'] = 'Special',
  c  = 'Constant',       -- command  → Constant fg
  R  = 'DiagnosticError', -- replace  → error red
  t  = 'DiagnosticInfo', -- terminal → info blue
}
local function mode_hl()
  local hl_name = mode_colors[vim.fn.mode():sub(1, 1)] or 'Function'
  local hl = vim.api.nvim_get_hl(0, { name = hl_name, link = false })
  local fg = hl.fg and string.format('#%06x', hl.fg) or nil
  local bg = vim.api.nvim_get_hl(0, { name = 'Normal', link = false })
  bg = bg.bg and string.format('#%06x', bg.bg) or '#000000'
  return { fg = bg, bg = fg, gui = 'bold' }
end

-- Active LSP client name shown in the center section
local function lsp_name()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then return '' end
  return '󰒋 ' .. clients[1].name
end

require('lualine').setup {
  options = {
    icons_enabled        = true,
    theme                = 'auto', -- follows any active colorscheme
    disabled_filetypes   = { statusline = {}, winbar = {} },
    show_modified_status = true,
    ignore_focus         = {},
    always_divide_middle = true,
    globalstatus         = false,
    refresh = {
      statusline = 1000,
      tabline    = 1000,
      winbar     = 1000,
    },
  },
  sections = {
    lualine_a = {
      {
        'fileformat',
        symbols = { unix = '', dos = '', mac = '' },
      },
      { 'mode', color = mode_hl },
      {
        icon_filename,
        file_status     = true,
        newfile_status  = false,
        path            = 0,
        shorting_target = 40,
        symbols = {
          modified = '[+]',
          readonly = '[-]',
          unnamed  = '[No Name]',
          newfile  = '[New]',
        },
      },
    },
    lualine_b = { 'branch', 'diff', 'diagnostics' },
    lualine_c = { lsp_name },
    lualine_x = { 'encoding', 'fileformat', 'filetype' },
    lualine_y = { 'progress' },
    lualine_z = { 'location' },
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = { 'filename' },
    lualine_x = { 'location' },
    lualine_y = {},
    lualine_z = {},
  },
  tabline         = {},
  winbar          = {},
  inactive_winbar = {},
  extensions      = {},
}
