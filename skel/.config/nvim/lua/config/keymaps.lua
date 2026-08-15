-- Custom keymaps: floating terminal (vim-floaterm) and code runner (F5/F6)
-- See https://www.lazyvim.org/keymaps for LazyVim default keymaps.

vim.g.mapleader = ' '

-- ─────────────────────────────────────────────────────────────
-- Floating terminal (vim-floaterm)
--   F4            → vertical split terminal (toggle)
--   Shift+F4      → horizontal split terminal (toggle)
--   Ctrl+Shift+F4 → floating terminal (toggle)
-- ─────────────────────────────────────────────────────────────

-- Toggles a named floaterm; creates it on first call.
function toggleFT(name, cmd)
    local bufnr = vim.fn['floaterm#terminal#get_bufnr'](name)
    if bufnr ~= -1 then
        vim.cmd(string.format('FloatermToggle %s', name))
    else
        vim.cmd(string.format('FloatermNew --name=%s %s', name, cmd))
    end
end

local name_win_v = 'vterminal'
local floaterm_cmd_v = '--wintype=vsplit --width=0.45'
vim.api.nvim_set_keymap('n', '<F4>', string.format(':lua toggleFT("%s", "%s")<CR>', name_win_v, floaterm_cmd_v), { noremap = true, silent = true })
vim.api.nvim_set_keymap('t', '<F4>', string.format('<C-\\><C-n>:lua toggleFT("%s", "%s")<CR>', name_win_v, floaterm_cmd_v), { noremap = true, silent = true })

local name_win_h = 'hterminal'
local floaterm_cmd_h = '--titleposition=left --wintype=split --height=0.25'
vim.api.nvim_set_keymap('n', '<S-F4>', string.format(':lua toggleFT("%s", "%s")<CR>', name_win_h, floaterm_cmd_h), { noremap = true, silent = true })
vim.api.nvim_set_keymap('t', '<S-F4>', string.format('<C-\\><C-n>:lua toggleFT("%s", "%s")<CR>', name_win_h, floaterm_cmd_h), { noremap = true, silent = true })

local name_win_f = 'fterminal'
local floaterm_cmd_f = '--title= --titleposition=left --position=center --wintype=floating --height=0.9 --width=0.9'
vim.api.nvim_set_keymap('n', '<S-C-F4>', string.format(':lua toggleFT("%s", "%s")<CR>', name_win_f, floaterm_cmd_f), { noremap = true, silent = true })
vim.api.nvim_set_keymap('t', '<S-C-F4>', string.format('<C-\\><C-n>:lua toggleFT("%s", "%s")<CR>', name_win_f, floaterm_cmd_f), { noremap = true, silent = true })

-- Konsole sends Shift+F4 as <F16> and Ctrl+Shift+F4 as <F40>
-- (verified with Ctrl-v in insert mode)
vim.api.nvim_set_keymap('n', '<F16>', string.format(':lua toggleFT("%s", "%s")<CR>', name_win_h, floaterm_cmd_h), { noremap = true, silent = true })
vim.api.nvim_set_keymap('t', '<F16>', string.format('<C-\\><C-n>:lua toggleFT("%s", "%s")<CR>', name_win_h, floaterm_cmd_h), { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<F40>', string.format(':lua toggleFT("%s", "%s")<CR>', name_win_f, floaterm_cmd_f), { noremap = true, silent = true })
vim.api.nvim_set_keymap('t', '<F40>', string.format('<C-\\><C-n>:lua toggleFT("%s", "%s")<CR>', name_win_f, floaterm_cmd_f), { noremap = true, silent = true })

-- ─────────────────────────────────────────────────────────────
-- Code runner — F5 (run) / F6 (interactive), filetype-aware
--
--   C / C++    → gcc/g++ compile then run
--   Java       → javac compile then java
--   Python     → python3 -B        (F6: python3 -Bi)
--   JavaScript → node              (F6: node -i -e "$(cat <file>)")
--   TypeScript → npx ts-node
--   Lua        → lua
--   Bash / Sh  → bash / sh
--   Ruby       → ruby              (F6: irb -r <file>)
--   Go         → go run
--   Rust       → rustc compile then run
--   PHP        → php
--   Perl       → perl
--   R          → Rscript
--   Julia      → julia
--   Kotlin     → kotlinc + java -jar
--
--   Layout variants:
--     F5 / F6             → vsplit
--     Shift+F5 / F6       → horizontal split
--     Ctrl+Shift+F5 / F6  → floating window
-- ─────────────────────────────────────────────────────────────

local ft_layouts = {
  v = '--wintype=vsplit --width=0.45 --autoinsert=false --autoclose=0',
  h = '--wintype=split --height=0.25 --autoinsert=false --autoclose=0',
  f = '--title= --titleposition=left --position=center --wintype=floating --height=0.9 --width=0.9 --autoinsert=false --autoclose=0',
}

-- Last executed source file; allows re-running from inside the terminal.
local last_src = nil

local function build_run_cmd(file, ft, interactive)
  local f   = vim.fn.shellescape(file)
  local out = vim.fn.shellescape(vim.fn.fnamemodify(file, ':r'))

  if ft == 'c' then
    return string.format('gcc -o %s %s -std=c23 -Wall -lm && %s', out, f, out)

  elseif ft == 'cpp' then
    return string.format('g++ -o %s %s -std=c++23 -Wall && %s', out, f, out)

  elseif ft == 'java' then
    local dir = vim.fn.shellescape(vim.fn.fnamemodify(file, ':h'))
    local cls = vim.fn.fnamemodify(file, ':t:r')
    return string.format('javac %s && java -cp %s %s', f, dir, cls)

  elseif ft == 'python' then
    return interactive and ('python3 -Bi ' .. f) or ('python3 -B ' .. f)

  elseif ft == 'javascript' then
    return interactive and string.format('node -i -e "$(cat %s)"', f)
                        or ('node ' .. f)

  elseif ft == 'typescript' then
    return 'npx ts-node ' .. f

  elseif ft == 'lua' then
    return 'lua ' .. f

  elseif ft == 'sh' then
    return 'sh ' .. f

  elseif ft == 'bash' then
    return 'bash ' .. f

  elseif ft == 'ruby' then
    return interactive and ('irb -r ' .. f) or ('ruby ' .. f)

  elseif ft == 'go' then
    return 'go run ' .. f

  elseif ft == 'rust' then
    return string.format('rustc -o %s %s && %s', out, f, out)

  elseif ft == 'php' then
    return 'php ' .. f

  elseif ft == 'perl' then
    return 'perl ' .. f

  elseif ft == 'r' then
    return 'Rscript ' .. f

  elseif ft == 'julia' then
    return 'julia ' .. f

  elseif ft == 'kotlin' then
    local jar = vim.fn.shellescape(vim.fn.fnamemodify(file, ':r') .. '.jar')
    return string.format('kotlinc %s -include-runtime -d %s && java -jar %s', f, jar, jar)
  end

  return nil
end

function RunCode(layout, interactive)
  local file, ft

  if vim.bo.buftype == '' then
    file, ft = vim.fn.expand('%:p'), vim.bo.filetype
    vim.cmd('write')
  elseif last_src then
    file, ft = last_src.file, last_src.ft
    vim.cmd('silent! wall')
  else
    vim.notify('RunCode: abra o arquivo-fonte antes de executar', vim.log.levels.WARN)
    return
  end

  local cmd = build_run_cmd(file, ft, interactive)
  if not cmd then
    vim.notify('RunCode: filetype nao suportado: ' .. (ft ~= '' and ft or '?'),
               vim.log.levels.WARN)
    return
  end
  last_src = { file = file, ft = ft }

  if vim.fn.exists(':FloatermNew') ~= 2 then
    pcall(function() require('lazy').load({ plugins = { 'vim-floaterm' } }) end)
  end
  if vim.fn.exists(':FloatermNew') ~= 2 then
    vim.notify('RunCode: vim-floaterm indisponivel -- verifique :Lazy e rode :Lazy sync',
               vim.log.levels.ERROR)
    return
  end

  pcall(vim.cmd, 'FloatermKill!')
  vim.cmd(string.format('FloatermNew --name=runterm %s bash -c %s',
          ft_layouts[layout], vim.fn.shellescape(cmd)))

end

-- F5: run
vim.keymap.set('n', '<F5>',     function() RunCode('v', false) end, { silent = true, desc = 'Run file (vsplit)' })
vim.keymap.set('n', '<S-F5>',   function() RunCode('h', false) end, { silent = true, desc = 'Run file (split)' })
vim.keymap.set('n', '<S-C-F5>', function() RunCode('f', false) end, { silent = true, desc = 'Run file (float)' })
vim.keymap.set('t', '<F5>',     [[<C-\><C-n>:lua RunCode('v', false)<CR>]], { silent = true })
vim.keymap.set('t', '<S-F5>',   [[<C-\><C-n>:lua RunCode('h', false)<CR>]], { silent = true })
vim.keymap.set('t', '<S-C-F5>', [[<C-\><C-n>:lua RunCode('f', false)<CR>]], { silent = true })

-- F6: interactive
vim.keymap.set('n', '<F6>',     function() RunCode('v', true) end, { silent = true, desc = 'Run file interactive (vsplit)' })
vim.keymap.set('n', '<S-F6>',   function() RunCode('h', true) end, { silent = true, desc = 'Run file interactive (split)' })
vim.keymap.set('n', '<S-C-F6>', function() RunCode('f', true) end, { silent = true, desc = 'Run file interactive (float)' })
vim.keymap.set('t', '<F6>',     [[<C-\><C-n>:lua RunCode('v', true)<CR>]], { silent = true })
vim.keymap.set('t', '<S-F6>',   [[<C-\><C-n>:lua RunCode('h', true)<CR>]], { silent = true })
vim.keymap.set('t', '<S-C-F6>', [[<C-\><C-n>:lua RunCode('f', true)<CR>]], { silent = true })

-- xterm legacy: Shift+F5 → <F17>, Shift+F6 → <F18>
vim.keymap.set('n', '<F17>', function() RunCode('h', false) end, { silent = true, desc = 'Run file (split)' })
vim.keymap.set('n', '<F18>', function() RunCode('h', true)  end, { silent = true, desc = 'Run interactive (split)' })
vim.keymap.set('t', '<F17>', [[<C-\><C-n>:lua RunCode('h', false)<CR>]], { silent = true })
vim.keymap.set('t', '<F18>', [[<C-\><C-n>:lua RunCode('h', true)<CR>]],  { silent = true })

-- xterm legacy: Ctrl+Shift+F5 → <F41>, Ctrl+Shift+F6 → <F42>
vim.keymap.set('n', '<F41>', function() RunCode('f', false) end, { silent = true, desc = 'Run file (float)' })
vim.keymap.set('n', '<F42>', function() RunCode('f', true)  end, { silent = true, desc = 'Run interactive (float)' })
vim.keymap.set('t', '<F41>', [[<C-\><C-n>:lua RunCode('f', false)<CR>]], { silent = true })
vim.keymap.set('t', '<F42>', [[<C-\><C-n>:lua RunCode('f', true)<CR>]],  { silent = true })

-- <leader> fallback (works in any terminal without Shift/Ctrl+Fn support)
vim.keymap.set('n', '<leader>rv', function() RunCode('v', false) end, { silent = true, desc = 'Run file (vsplit)' })
vim.keymap.set('n', '<leader>rh', function() RunCode('h', false) end, { silent = true, desc = 'Run file (split)' })
vim.keymap.set('n', '<leader>rf', function() RunCode('f', false) end, { silent = true, desc = 'Run file (float)' })
vim.keymap.set('n', '<leader>iv', function() RunCode('v', true)  end, { silent = true, desc = 'Run interactive (vsplit)' })
vim.keymap.set('n', '<leader>ih', function() RunCode('h', true)  end, { silent = true, desc = 'Run interactive (split)' })
vim.keymap.set('n', '<leader>if', function() RunCode('f', true)  end, { silent = true, desc = 'Run interactive (float)' })

-- ─────────────────────────────────────────────────────────────
-- DAP (debugger)
--   F7  → toggle breakpoint
--   F8  → continue
--   F9  → step over
--   F10 → step into
--   F11 → step out
--   F12 → terminate
-- ─────────────────────────────────────────────────────────────
vim.api.nvim_set_keymap('n', '<F7>',  [[:DapToggleBreakpoint<CR>]], { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<F8>',  [[:DapContinue<CR>]],         { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<F9>',  [[:DapStepOver<CR>]],         { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<F10>', [[:DapStepInto<CR>]],         { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<F11>', [[:DapStepOut<CR>]],          { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<F12>', [[:DapTerminate<CR>]],        { noremap = true, silent = true })
