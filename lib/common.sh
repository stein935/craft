#!/bin/bash

# string formatters
if [ -t 1 ]
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

# Errors and help
command_help () {
  echo ""
  cat ${craft_home_dir}/config/help/${1}_help.txt
  echo "
  "
  if [ "$2" != "" ]; then
    exit 0
  else
    exit 1
  fi
}

missing_argument () {
  warn "
Invalid option: -$2 requires an argument"
  command_help $1 
}

invalid_command () {
  warn "
Invalid command: $2"
  command_help $1
}

invalid_option () {
  warn "
Invalid option: -$2"
  command_help $1
}

missing_required_option () {
  warn "
Missing option: $1 requires \"$2\""
  command_help $1
}

list_properties () {
  count=0
  while IFS="" read -r line || [ -n "$line" ]; do
    if [[ $count -gt 1 ]]; then
      prop=$(echo "${line%=*}" | tr .- _)
      set=$(printf '%s\n' "${line##*=}")

      export $prop="$set"
    fi
    (( count++ ))
  done < ${1}
}

get_properties () {
  list_properties ${craft_server_dir}/${server_name}/server.properties
  list_properties ${craft_server_dir}/${server_name}/fabric-server-launcher.properties
}

find_server () {
  if ! [[ -d ${craft_server_dir}/"${1}" ]]; then
    warn "No server named ${1} in ${craft_server_dir}"
    exit 1
  fi
}