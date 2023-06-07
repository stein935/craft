#!/usr/bin/env bash

# Bits 
ring_bell() {
  [ -t 1 ] && printf "\a"
}

# string formatters
[ -t 1 ] && tty_escape() { printf "\033[%sm" "$1"; } || tty_escape() { :; }
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
  for arg in "$@"; do
    printf " "
    printf "%s" "${arg// /\ }"
  done
}

chomp() { printf "%s" "${1/"$'\n'"/}"; }

ohai() { printf "${tty_blue}>>>>>>>${tty_bold}: %s${tty_reset}\n" "$(shell_join "$@")"; }

warn() { ring_bell; printf "${tty_red}Warning${tty_reset}: %s\n" "$(chomp "$1")" >&2; }

# Errors and help
match_command () {

  aliases=("${3}" "${2}")

  for alias in ${aliases[@]}; do 
    if [[ "${alias}" == "${1}" ]]; then
      export op="${2}"
    fi
  done
}

command_help () {
  printf '\n%s\n\n' "$(cat ${CRAFT_HOME_DIR}/config/help/${1}_help.txt)"
  exit ${2}
}

missing_argument () {
  warn "Invalid option: -$2 requires an argument"
  command_help $1 1
}

invalid_command () {
  warn "Invalid command: $2"
  command_help $1 1
}

invalid_option () {
  warn "Invalid option: -$2"
  command_help $1 1
}

missing_required_option () {
  warn "Missing option: $1 requires \"$2\""
  command_help $1 1
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
  list_properties ${CRAFT_SERVER_DIR}/${server_name}/server.properties
  list_properties ${CRAFT_SERVER_DIR}/${server_name}/fabric-server-launcher.properties
}

find_server () {
  if ! [[ -d ${CRAFT_SERVER_DIR}/"${1}" ]]; then
    warn "No server named ${1} in ${CRAFT_SERVER_DIR}"
    exit 1
  fi
}

discord_message () {

  message () {
    cat <<EOF
{
  "embeds":[{
    "title": "${1}",
    "description":"${2}",
    "timestamp":"$(date +'%Y-%m-%dT%H:%M:%S%z')",
    "color":"${3}",
    "author":{
      "name":"Craft CLI - ${4}",
      "url":"https://github.com/stein935/craft"
    }
  }]
}
EOF
  }

  # POST request to Discord Webhook
  curl -H "Content-Type: application/json" -X POST -d "$(message "$1" "$2" "$3" "$4")" $discord_webhook

}