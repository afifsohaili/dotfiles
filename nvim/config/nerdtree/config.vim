let NERDTreeMinimalUI = 1
let NERDTreeDirArrows = 1
let g:NERDTreeWinSize = 30
let g:nerdtree_tabs_open_on_gui_startup = 0
let g:nerdtree_tabs_focus_on_files = 1
let NERDTreeIgnore = ['^node_modules$', '_darcs']
function! OpenNerdTree()
  if &modifiable && strlen(expand('%')) > 0 && !&diff
    NERDTreeFind
  else
    NERDTreeToggle
  endif
endfunction
nnoremap <silent> <C-\> :call OpenNerdTree()<CR>

filetype plugin on
filetype indent on
