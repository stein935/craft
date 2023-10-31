#!/usr/bin/env bash

command="restart"
server_name=false
test=false
monitor=

restart_command() {

  [ -z "$1" ] && command_help "$command" 1

  while getopts ":n:mht" opt; do
    case $opt in
    n) server_name="$OPTARG" ;;
    m) monitor="m" ;;
    h) command_help "$command" 0 ;;
    t) test=true ;;
    :) missing_argument "$command" "$OPTARG" ;;
    *) invalid_option "$command" "$OPTARG" ;;
    esac
  done

  [[ "${server_name}" == false ]] && missing_required_option "$command" "-n"

  find_server "${server_name}"

  if $test; then
    echo "${tty_yellow}"
    indent "command                 : $command        "
    indent "server_name             : $server_name    "
    indent "test                    : $test           "
    echo "${tty_reset}"
  fi

  restart_server

}

restart_server() {

  execute "$0" "stop" "-${monitor}fn" "${server_name}"
  execute "$0" "start" "-dn" "${server_name}"
  echo "$(date) : Restart: \"${server_name}\" was restarted." >>"${CRAFT_SERVER_DIR}/${server_name}/logs/monitor/$(date '+%Y-%m').log"
  $test && runtime && echo
  exit 0

}
