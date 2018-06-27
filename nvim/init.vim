if empty(glob('~/.config/nvim/autoload/plug.vim'))
  silent !curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs
        \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall
endif

" General settings
source ~/.config/nvim/config/general.vim

let config = split(globpath("~/.config/nvim/config", "*"), "\n")

call plug#begin()
  for l in config
    let s:package = l . '/packages.vim'
    if filereadable(s:package)
      exe "source" s:package
    endif
  endfor
call plug#end()

for l in config
  let s:config = l . '/config.vim'
  if filereadable(s:config)
    exe "source" s:config
  endif
endfor
