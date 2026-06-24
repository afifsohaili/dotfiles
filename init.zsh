for config_file ($HOME/Projects/dotfiles/**/*.zsh(N)) do
  if [ "$config_file" != "$HOME/Projects/dotfiles/init.zsh" ]; then
    source $config_file
  fi
done
