-- Colorscheme plugins
-- Switch themes on the fly with <leader>fc (Telescope colorscheme picker)
-- or :colorscheme <name>. Active theme is set in lua/config/settings.lua.

return {

  -- ── Dark themes ───────────────────────────────────────────────────────────
  { 'catppuccin/nvim',              name = 'catppuccin', priority = 1000 },
  { 'Mofiqul/vscode.nvim' },
  { 'navarasu/onedark.nvim' },
  { 'NTBBloodbath/doom-one.nvim' },
  { 'nyoom-engineering/oxocarbon.nvim' },  -- requires: luarocks lua5.1 liblua5.1-0-dev
  { 'EdenEast/nightfox.nvim' },
  { 'rose-pine/neovim',             name = 'rose-pine' },
  { 'cpea2506/one_monokai.nvim' },
  { 'habamax/vim-polar' },
  { 'folke/tokyonight.nvim',        lazy = true, opts = { style = 'moon' } },
  { 'polirritmico/monokai-nightasty.nvim', lazy = false, priority = 1000 },

  -- ── Light themes ──────────────────────────────────────────────────────────
  { 'projekt0n/github-nvim-theme',  priority = 1000 },
  { 'cormacrelf/vim-colors-github' },
  { 'romgrk/github-light.vim' },
  { 'Mofiqul/adwaita.nvim',         lazy = false, priority = 1000 },
  { 'miikanissi/modus-themes.nvim', lazy = false, priority = 1000 },
  { 'rmehri01/onenord.nvim' },

}
