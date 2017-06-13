for config_file ($HOME/dotfiles/*.zsh) do
  if [ "$config_file" != "$HOME/dotfiles/init.zsh" ]; then
    source $config_file
  fi
done
