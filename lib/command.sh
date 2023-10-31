#!/usr/bin/env bash

command="command"
server_command=false
server_name=false
test=false

command_command() {

  [ -z "$1" ] && command_help "$command" 1

  while getopts ":n:c:th" opt; do
    case $opt in
    n) server_name="$OPTARG" ;;
    c) server_command="$OPTARG" ;;
    h) command_help "$command" 0 ;;
    t) test=true ;;
    :) missing_argument "$command" "$OPTARG" ;;
    *) invalid_option "$command" "$OPTARG" ;;
    esac
  done

  [[ "$server_name" == false ]] && [[ "$server_command" == false ]] && missing_required_option "$command" "-n and -c"

  find_server "${server_name}"

  get_properties

  if $test; then
    echo "${tty_yellow}"
    indent "command                 : $command        "
    indent "server_command          : $server_command "
    indent "server_name             : $server_name    "
    indent "test                    : $test           "
    echo "${tty_reset}"
  fi

  command_server

}

command_server() {
  if ! server_status &>/dev/null; then
    warn "\"${server_name}\" is not running"
    $test && echo && runtime && echo
    exit 1
  fi

  fwhip "Sending \"${server_command}\" to \"${server_name}\" Minecraft server"
  execute "cat" "${CRAFT_SERVER_DIR}/${server_name}/logs/latest.log" >"${CRAFT_SERVER_DIR}/${server_name}/logs/latest.log.tmp"

  cd "${CRAFT_SERVER_DIR}/${server_name}"
  pipe=command-pipe
  exec 8<>$pipe

  printf '%s\r' "${server_command}" >>$pipe

  # execute "screen" "-S" "$server_name" "-p" "0" "-X" "stuff" "$(printf '%s\r' "${server_command}")" &

  while [ 1 ]; do
    compare=$(comm -23 "${CRAFT_SERVER_DIR}/${server_name}/logs/latest.log" "${CRAFT_SERVER_DIR}/${server_name}/logs/latest.log.tmp")
    if [ -n "$compare" ]; then
      # echo "${tty_bold}Server logs${tty_reset}:"
      # echo "$compare"
      echo "$(date) : Command: \"${server_command}\" sent to \"${server_name}\". Server log: ${compare}" >>"$CRAFT_SERVER_DIR/$server_name/logs/monitor/$(date '+%Y-%m').log"
      execute "rm" "${CRAFT_SERVER_DIR}/${server_name}/logs/latest.log.tmp"
      break
    fi
    sleep 1
  done

  $test && echo && runtime && echo
  exit 0
}
