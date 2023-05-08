#!/bin/bash
script_pwd=$(pwd)
if [ -d $HOME/bin/craft ]; then
  echo "craft is already installed on this machine"
else
  mkdir -p $HOME/bin/craft && cd $HOME/bin/craft
  echo "Installing craft"
  mkdir lib
  cp -r $script_pwd/lib/* ./lib
  cp $script_pwd/craft .
  echo "Adding craft to bash commands"
  current_profile=""
  if [ ! -e "${HOME}/.bash_profile" ]; then
    touch $HOME/.bash_profile
    current_profile=$(cat $HOME/.profile)
  else
    current_profile=$(sed '/export PATH/d' $HOME/.bash_profile)
  fi
  printf '%s\n' "export PATH=${HOME}/bin/craft:${PATH}" \
                "$current_profile" > $HOME/.bash_profile
  echo "Install complete"
fi