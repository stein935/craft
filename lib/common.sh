#!/usr/bin/env bash

# Bits
ring_bell() { [ -t 1 ] && printf "\a"; }

# string formatters
[ -t 1 ] && tty_escape() { printf "\033[%sm" "$1"; } || tty_escape() { :; }
tty_mkbold() { tty_escape "1;$1"; }
tty_underline="$(tty_escape "4;39")"
tty_blue_bold="$(tty_mkbold 34)"
tty_blue="$(tty_escape "0;34")"
tty_red_bold="$(tty_mkbold 31)"
tty_red="$(tty_escape "0;31")"
tty_yellow_bold="$(tty_mkbold 33)"
tty_yellow="$(tty_escape "0;33")"
tty_cyan_bold="$(tty_mkbold 36)"
tty_cyan="$(tty_escape "2;36")"
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

abort() {
  printf "%s\n" "$@" >&2
  exit 1
}

execute() {
  if ! "$@"; then
    abort "$(printf "Failed during: %s" "$(shell_join "$@")")"
  fi
}

fwhip() { printf "${tty_blue_bold}>>>>>>>${tty_bold}: %s${tty_reset}\n" "$@"; }
warn() {
  ring_bell
  printf "${tty_red_bold}Warning${tty_bold}: %s${tty_reset}\n" "$@" >&2
}
indent() {
  space_count=${2:-4}
  spaces=""
  count=0
  while [[ $count -lt $space_count ]]; do
    spaces+=" "
    ((count++))
  done
  printf "${spaces}%s\n" "$1"
}
min_sec() { printf "%dm %ds" "$((10#$1 / 60))" "$((10#$1 % 60))"; }

# Errors and help
match_command() {
  aliases=("${3}" "${2}")
  for alias in ${aliases[@]}; do
    if [[ "${alias}" == "${1}" ]]; then
      export op="${2}"
    fi
  done
}

command_help() {
  printf '\n%s\n\n' "$(cat ${CRAFT_HOME_DIR}/config/help/${1}_help.txt)"
  exit ${2}
}

missing_argument() {
  warn "Invalid option: -$2 requires an argument"
  command_help $1 1
}

invalid_command() {
  warn "Invalid command: $2"
  command_help $1 1
}

invalid_option() {
  warn "Invalid option: -$2"
  command_help $1 1
}

missing_required_option() {
  warn "Missing option: $1 requires \"$2\""
  command_help $1 1
}

runtime() {
  indent "${tty_yellow}Runtime: $(min_sec $(($(date +%s) - START)))${tty_reset}"
}

pid() {
  PID=($(sudo lsof -i :$server_port | grep $server_port | awk '{print $2}'))
}

list_properties() {
  count=0
  while IFS="" read -r line || [ -n "$line" ]; do
    if [[ $count -gt 1 ]]; then
      prop=$(echo "${line%=*}" | tr .- _)
      set=$(printf '%s\n' "${line##*=}")
      export $prop="$set"
    fi
    ((count++))
  done <"${1}"
}

get_properties() {
  list_properties "${CRAFT_SERVER_DIR}/${server_name}/server.properties"
  list_properties "${CRAFT_SERVER_DIR}/${server_name}/fabric-server-launcher.properties"
}

find_server() {
  if ! [[ -d "${CRAFT_SERVER_DIR}/${1}" ]]; then
    warn "No server named ${1} in ${CRAFT_SERVER_DIR}"
    exit 1
  fi
}

server_status() {

  pid

  if [ $PID ]; then
    fwhip "\"${server_name}\" Minecraft server running on port: ${server_port} PID: ${PID}"
    echo "$(date) : Status: \"${server_name}\" is running on port: ${server_port} PID: ${PID}" >>"${CRAFT_SERVER_DIR}/${server_name}/logs/monitor/$(date '+%Y-%m').log"
    (exit 0)
  else
    warn "\"${server_name}\" is not running"
    echo "$(date) : Status: \"${server_name}\" is not running" >>"${CRAFT_SERVER_DIR}/${server_name}/logs/monitor/$(date '+%Y-%m').log"
    (exit 1)
  fi

}

discord_message() {

  message() {
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
  curl -H "Content-Type: application/json" -X POST -d "$(message "$1" "$2" "$3" "$4")" $discord_webhook &>/dev/null

}

boolean() {
  case $1 in
  true) echo true ;;
  false) echo false ;;
  *) echo true ;;
  esac
}
