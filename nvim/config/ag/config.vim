if executable('ag')
  let g:ackprg = 'ag --vimgrep'
endif

" Mappings
nmap <leader>ag :Ag ""<Left>
vmap <leader>ag y :Ag "<C-R>""<CR>
