#!/usr/bin/env bash

command="status"
server_name=false
test=false

status_command() {

  # [ -z "$1" ] && command_help "$command" 1

  while getopts ":n:ht" opt; do
    case "$opt" in
    n) server_name=${OPTARG} ;;
    h) command_help "${command}" 0 ;;
    t) test=true ;;
    :) missing_argument "$command" "$OPTARG" ;;
    *) invalid_option "$command" "$OPTARG" ;;
    esac
  done

  # [[ "${server_name}" == false ]] && missing_required_option "$command" "-n"

  if $test; then
    echo "${tty_yellow}"
    indent "command                 : $command        "
    indent "server_name             : $server_name    "
    indent "test                    : $test           "
    echo "${tty_reset}"
  fi

  $test && echo && runtime && echo

  if [[ "${server_name}" == false ]]; then
    servers=$(ls "${CRAFT_SERVER_DIR}")
    while IFS=$'\t' read -r server; do
      server_name="${server}"
      get_properties
      server_status
    done <<<"${servers[@]}"
  else
    find_server "${server_name}"
    get_properties
    server_status
  fi

  exit $?

}
