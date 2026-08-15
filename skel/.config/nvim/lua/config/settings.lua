-- General editor settings

vim.cmd([[
set nocompatible
syntax on
filetype plugin indent on
set encoding=utf-8
set showcmd
set showmode
set cmdheight=1
set scrolloff=10
set splitbelow
set splitright
set conceallevel=0
set tabstop=4
set shiftwidth=4
set autoindent
set smarttab
set expandtab
set showtabline=2
set nobackup
set nowritebackup
set clipboard=unnamedplus
set laststatus=2
set number
set ruler
set cursorline
set hidden
set backspace=start,eol,indent
set mouse=a
set termguicolors
set guifont=Hack\ Nerd\ Font:h11
set ttyfast
set nornu
set textwidth=79
set wrapmargin=0
set showbreak=↪
set wrap linebreak
]])

-- Draw thin continuous line characters for splits and statusline
vim.opt.fillchars = {
  stl   = '─',
  stlnc = '─',
  vert  = '│',
}

-- Always show the sign column
vim.opt.signcolumn = 'yes'

-- Disable autoformat on save (format manually with <leader>mp or :Format)
vim.g.autoformat = false

-- Toggle between dark (catppuccin-mocha) and light (wbs)
-- Usage: :ToggleTheme  or  <leader>tt
local function toggle_theme()
  if vim.o.background == 'dark' then
    vim.opt.background = 'light'
    vim.cmd.colorscheme('wbs')
  else
    vim.opt.background = 'dark'
    vim.cmd.colorscheme('catppuccin-mocha')
  end
end

vim.api.nvim_create_user_command('ToggleTheme', toggle_theme, {})
vim.keymap.set('n', '<leader>tt', toggle_theme, { desc = 'Toggle dark/light theme' })

-- Detect the desktop's dark/light preference, independent of the desktop
-- environment or display server (Wayland or X11). Tries, in order:
--   1. XDG Desktop Portal (freedesktop.org standard, D-Bus based — works on
--      KDE, GNOME and most modern DEs regardless of Wayland/X11)
--   2. KDE Plasma (kdeglobals ColorScheme), for setups without a running
--      xdg-desktop-portal
--   3. GNOME / gsettings, for setups exposing only that schema
-- Returns nil (no preference detected) if none of the above succeed.
local function detect_dark_mode()
  if vim.fn.executable('gdbus') == 1 then
    local out = vim.fn.system({
      'gdbus', 'call', '--session',
      '--dest', 'org.freedesktop.portal.Desktop',
      '--object-path', '/org/freedesktop/portal/desktop',
      '--method', 'org.freedesktop.portal.Settings.ReadOne',
      'org.freedesktop.appearance', 'color-scheme',
    })
    if vim.v.shell_error == 0 then
      local value = out:match('uint32 (%d)')
      if value == '1' then return true end
      if value == '2' then return false end
    end
  end

  local kreadconfig = vim.fn.executable('kreadconfig6') == 1 and 'kreadconfig6'
    or (vim.fn.executable('kreadconfig5') == 1 and 'kreadconfig5' or nil)
  if kreadconfig then
    local out = vim.fn.system({ kreadconfig, '--file', 'kdeglobals', '--group', 'General', '--key', 'ColorScheme' })
    if vim.v.shell_error == 0 and out ~= '' then
      return out:lower():find('dark') ~= nil
    end
  end

  if vim.fn.executable('gsettings') == 1 then
    local out = vim.fn.system({ 'gsettings', 'get', 'org.gnome.desktop.interface', 'color-scheme' })
    if vim.v.shell_error == 0 then
      return out:find('dark') ~= nil
    end
  end

  return nil
end

-- Apply theme based on the system dark/light preference.
-- dark  → catppuccin-mocha
-- light → wbs  (custom classroom/projector theme)
-- No preference detected → defaults to dark.
-- Override at any time with :colorscheme <name> or <leader>tt
local function apply_theme()
  local is_dark = detect_dark_mode()
  if is_dark == nil then is_dark = true end

  if is_dark then
    vim.opt.background = 'dark'
    vim.cmd.colorscheme('catppuccin-mocha')
  else
    vim.opt.background = 'light'
    vim.cmd.colorscheme('wbs')
  end
end

apply_theme()
