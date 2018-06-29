let g:deoplete#enable_at_startup = 1

autocmd CompleteDone * silent! pclose!

set completeopt-=preview
