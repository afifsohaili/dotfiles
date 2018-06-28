Plug 'Galooshi/vim-import-js', {
      \ 'do': 'yarn global add import-js'
      \ } " ImportJS
Plug 'flowtype/vim-flow', {
      \ 'do': 'yarn global add flow-bin',
      \ 'for': ['javascript', 'javascript.jsx']
      \ }

" Disable flow by default, unless specifically turned on per project's .lvimrc
let g:flow#enable = 0
let g:flow#autoclose = 1
