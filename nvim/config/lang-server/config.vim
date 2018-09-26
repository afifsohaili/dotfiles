let g:LanguageClient_serverCommands = {
      \ 'vue': ['vls'],
      \ 'javascript': ['javascript-typescript-stdio'],
      \ 'javascript.jsx': ['javascript-typescript-stdio'],
      \ 'typescript': ['javascript-typescript-stdio'],
      \ 'typescript.tsx': ['javascript-typescript-stdio']
      \ }
let g:LanguageClient_autoStart = 1 " Automatically start language servers.

nnoremap <leader>f :call LanguageClient#textDocument_definition()<CR>
nnoremap gm :call LanguageClient_contextMenu()<CR>
