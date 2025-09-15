# Setup

1. git clone to ~/Projects/dotfiles
2. install homebrew
3. `brew bundle install --file ~/Projects/dotfiles/Brewfile`
3. `asdf plugin add ruby`
3. `asdf plugin add nodejs`
3. `asdf plugin add python`
3. `asdf plugin add postgres`
3. `asdf plugin add redis`
4. ln -s $HOME/Projects/dotfiles/tmux/tmux.conf $HOME/.tmux.conf
5. ln -s $HOME/Projects/dotfiles/starship/starship.toml $HOME/.config/
6. Install oh my zsh
7. Load `source $HOME/Projects/dotfiles/init.zsh` to .zshrc

