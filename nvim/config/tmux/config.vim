" Tmux runner settings
nnoremap <leader>va :VtrAttachToPane<cr>
nnoremap <leader>vfc :VtrFlushCommand<cr>
nnoremap <leader>vsf :VtrSendFile<cr>
nnoremap <leader>vrs :VtrSendCommandToRunner<cr>

" Set autoread
" This is used by tmux-plugins/vim-tmux-focus-events
set autoread

" Splits Navigation
nnoremap <C-j> <C-w><C-j>
nnoremap <C-k> <C-w><C-k>
nnoremap <C-l> <C-w><C-l>
nnoremap <C-h> <C-w><C-h>

" Tmux navigator settings
let g:tmux_navigator_no_mappings = 1

nnoremap <silent> <C-h> :TmuxNavigateLeft<cr>
nnoremap <silent> <C-j> :TmuxNavigateDown<cr>
nnoremap <silent> <C-k> :TmuxNavigateUp<cr>
nnoremap <silent> <C-l> :TmuxNavigateRight<cr>
