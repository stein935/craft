#!/bin/bash

uninstall=false
delete_servers=false
messages=()

# string formatters
if [[ -t 1 ]]
then
  tty_escape() { printf "\033[%sm" "$1"; }
else
  tty_escape() { :; }
fi
tty_mkbold() { tty_escape "1;$1"; }
tty_underline="$(tty_escape "4;39")"
tty_blue="$(tty_mkbold 34)"
tty_red="$(tty_mkbold 31)"
tty_bold="$(tty_mkbold 39)"
tty_reset="$(tty_escape 0)"

shell_join() {
  local arg
  printf "%s" "$1"
  shift
  for arg in "$@"
  do
    printf " "
    printf "%s" "${arg// /\ }"
  done
}

chomp() {
  printf "%s" "${1/"$'\n'"/}"
}

ohai() {
  printf "${tty_blue}==>${tty_bold} %s${tty_reset}\n" "$(shell_join "$@")"
}

warn() {
  printf "${tty_red}Warning${tty_reset}: %s\n" "$(chomp "$1")" >&2
}

while true; do

  ohai "Uninstall Craft CLI?"
  read -p "(y/n) : " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then

    uninstall=true

    break

  elif [[ $REPLY =~ ^[Nn]$ ]]; then

    warn "Cancelling uninstall" 

    exit 0

  else

    echo "Please enter y or n"

  fi

done

while true; do

  ohai "Delete all servers in ${HOME}/Craft?"
  read -p "(y/n) : " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then

    delete_servers=true

    break

  elif [[ $REPLY =~ ^[Nn]$ ]]; then

    warn "Leaving servers alone" 

    break

  else

    echo "Please enter y or n"

  fi

done

directories=(
  /usr/local/bin/craft
  /usr/local/craft
)
if [ "$uninstall" == true ]; then 
  ohai "Stopping all servers"
  servers=$(craft -ls)
  echo "$servers"
  for server in $servers
  do
    craft stop -n $server
  done
  ohai "Deleting Craft CLI files"
  for dir in $directories
  do
    rm -r $dir
    echo "Deleted: $dir"
    message+="CLI deleted"
  done
fi

if [ "$delete_servers" == true ]; then

   while true; do

  ohai "Permanently delete all Minecraft servers and worlds in ${HOME}/Craft?"
  read -p "(y/n) : " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then

    rm -r $HOME/Craft
    echo "Deleted: $HOME/Craft"
    message+="servers deleted"

    break

  elif [[ $REPLY =~ ^[Nn]$ ]]; then

    warn "Leaving servers alone" 

    break

  else

    echo "Please enter y or n"

  fi

done

for message in $messages
do
  ohai "$message"
done