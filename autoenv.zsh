if [ -d "$HOME/.autoenv" ]
then
else
  echo "~/.autoenv missing. Cloning from github..."
  git clone git@github.com:inishchith/autoenv.git ~/.autoenv
fi
export AUTOENV_ENV_FILENAME=".rc"
source $HOME/.autoenv/activate.sh
