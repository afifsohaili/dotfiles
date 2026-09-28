if [ -d "$HOME/.autoenv" ]; then
  :
else
  echo "~/.autoenv missing. Cloning from github..."
  git clone https://github.com/inishchith/autoenv.git ~/.autoenv
fi
export AUTOENV_ENV_FILENAME=".rc"
[ -r "$HOME/.autoenv/activate.sh" ] && source "$HOME/.autoenv/activate.sh"
