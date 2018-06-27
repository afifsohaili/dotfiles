" Git
au FileType gitcommit set tw=72
au FileType gitcommit set synmaxcol=72

" Git gutter
let g:gitgutter_map_keys = 0
nmap <leader>h <Plug>GitGutterNextHunk
nmap <leader>l <Plug>GitGutterPrevHunk
