" Make vim use 256 colors
set t_Co=256
set t_AB=^[[48;5;%dm
set t_AF=^[[38;5;%dm

" Set colorscheme
colorscheme darcula

set background=dark
set colorcolumn=80
set nocursorline
set nowrap
set number
" Make search results appear in the middle of the screen
set scrolloff=40
set termguicolors

" straight line for vertical split panes instead of dot
set fillchars=vert:\│
hi VertSplit ctermfg=60 ctermbg=236 cterm=NONE guifg=#999999 guibg=#323232 gui=NONE

" Set colorcolumn color
hi ColorColumn guibg=#444444

" Highlight extra whitespace better
hi ExtraWhitespace ctermbg=160 guibg=#ff0000
