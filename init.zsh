for config_file ($HOME/.yadr/*.zsh) do
  if [ "$config_file" != "$HOME/.yadr/init.zsh" ]; then
    source $config_file
  fi
done
