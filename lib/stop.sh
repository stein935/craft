#!/usr/bin/env bash

command="stop"
server_name=false
force=false
test=false

stop_command() {

  [ -z "$1" ] && command_help "$command" 1

  while getopts ":n:fht" opt; do
    case $opt in
    n) server_name="$OPTARG" ;;
    f) force=true ;;
    h) command_help "$command" 0 ;;
    t) test=true ;;
    :) missing_argument "$command" "$OPTARG" ;;
    *) invalid_option "$command" "$OPTARG" ;;
    esac
  done

  [[ "${server_name}" == false ]] && missing_required_option "$command" "-n"

  find_server "${server_name}"

  get_properties

  if $test; then
    echo "${tty_yellow}"
    indent "command                 : $command        "
    indent "server_name             : $server_name    "
    indent "force                   : $force          "
    indent "test                    : $test           "
    echo "${tty_reset}"
  fi

  stop_server

}

stop_server() {

  pids
  screens

  if [ -z "${PIDS[@]}" ]; then
    warn "No server running on port: ${server_port}"
    ! $force && indent "To force stop run:" && indent "craft stop -fn \"${server_name}\"" "6" && exit 1 || warn "Force stopping all related processes ... just in case"
  else
    fwhip "Stopping \"${server_name}\" Minecraft server"
  fi

  execute "crontab" "-l" >"${CRAFT_SERVER_DIR}/.crontab"
  execute "sed" "-i" ".bak" "/${server_name}/d" "${CRAFT_SERVER_DIR}/.crontab"
  execute "crontab" "${CRAFT_SERVER_DIR}/.crontab" && execute "rm" "${CRAFT_SERVER_DIR}/.crontab"

  if [ ${#SCREENS[@]} -gt 0 ]; then
    for screen in "${SCREENS[@]}"; do
      execute "screen" "-S" "${screen[@]}" "-p" "0" '-X' "stuff" "$(printf '%s\r' "/stop")"
      sleep 3
      while [ -n "$(screen -ls "${server_name}" | grep -o "${screen[@]}")" ]; do
        execute "screen" "-S" "${screen[@]}" "-p" "0" '-X' "stuff" "$(printf '%s\r' "exit")"
        sleep 1
      done
    done
    pids
    for pid in "${PIDS[@]}"; do
      $force && execute "kill" "-9" "${pid}"
    done
  fi

  $force && screen -wipe &>/dev/null

  server_status &>/dev/null

  if [[ $? == 1 ]] &>/dev/null; then
    fwhip "\"${server_name}\" Minecraft server stopped"
    echo "$(date) : Stop: \"${server_name}\" stopped" >>"${CRAFT_SERVER_DIR}/${server_name}/logs/monitor/$(date '+%Y-%m').log"
  else
    warn "Failed to stop \"${server_name}\""
    $test && echo && runtime && echo
    exit 1
  fi
  $test && echo && runtime && echo
  exit 0

}
