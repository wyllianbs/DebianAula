" Neovim-Qt GUI configuration

if exists('g:neovide')
  let g:neovide_font_hinting = 'none'
  let g:neovide_font_edging  = 'subpixelantialias'
endif

if exists(':GuiScrollBar')
  GuiScrollBar 1
endif

" Base GUI settings
set guifont=Hack\ Nerd\ Font:h11
set encoding=utf-8
set mouse=a
set termguicolors
set ruler
set ttyfast
set laststatus=2
set showmode
set showcmd
set nornu
set textwidth=79
set wrapmargin=0
set showbreak=↪
set wrap linebreak

" Font zoom — Ctrl+= / Ctrl+- / Ctrl+0
function! Zoom(amount) abort
  call ZoomSet(matchstr(&guifont, '\d\+$') + a:amount)
endfunc

function! ZoomSet(font_size) abort
  let &guifont = substitute(&guifont, '\d\+$', a:font_size, '')
endfunc

noremap <silent> <C-=> :call Zoom(v:count1)<CR>
noremap <silent> <C--> :call Zoom(-v:count1)<CR>
noremap <silent> <C-0> :call ZoomSet(11)<CR>

" Right-click context menu (copy / cut / paste)
nnoremap <silent><RightMouse> :call GuiShowContextMenu()<CR>
inoremap <silent><RightMouse> <Esc>:call GuiShowContextMenu()<CR>
xnoremap <silent><RightMouse> :call GuiShowContextMenu()<CR>gv
snoremap <silent><RightMouse> <C-G>:call GuiShowContextMenu()<CR>gv
