" Set , as the leader key
let mapleader=","   " leader is comma

" Clipboard
set clipboard+=unnamedplus

" Split window remaps
nnoremap vv <C-w>v
nnoremap ss <C-w>s

" Lazyredraw will not render every macro repetitions. Good for performance
set lazyredraw

" Map arrow keys to resize splits
nmap <silent> <Left> :vertical resize +5<CR>
nmap <silent> <Right> :vertical resize -5<CR>
nmap <silent> <Up> :resize +5<CR>
nmap <silent> <Down> :resize -5<CR>
