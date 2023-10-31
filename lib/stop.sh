#!/usr/bin/env bash

command="stop"
server_name=false
force=false
monitor=false
test=false

stop_command() {

  [ -z "$1" ] && command_help "$command" 1

  while getopts ":n:fmht" opt; do
    case $opt in
    n) server_name="$OPTARG" ;;
    m) monitor=true ;;
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
    indent "monitor                 : $monitor        "
    indent "test                    : $test           "
    echo "${tty_reset}"
  fi

  stop_server

}

stop_server() {

  pid

  if ! [ $PID ]; then
    warn "No server running on port: ${server_port}"
    ! $force && indent "To force stop run:" && indent "craft stop -fn \"${server_name}\"" "6" && exit 1 || warn "Force stopping all related processes ... just in case"
  else
    fwhip "Stopping \"${server_name}\" Minecraft server"
  fi

  $monitor || fwhip "Checking for sudo ..." && sudo ls &>/dev/null

  if ! $monitor; then
    sudo launchctl list | grep "craft.${server_name// /}.daemon" &>/dev/null && [ -f "/Library/LaunchDaemons/craft.${server_name// /}.daemon.plist" ] && sudo launchctl unload /Library/LaunchDaemons/craft.${server_name// /}.daemon.plist
    [ -f "/Library/LaunchDaemons/craft.${server_name// /}.daemon.plist" ] && sudo rm -f /Library/LaunchDaemons/craft.${server_name// /}.daemon.plist
  fi

  cd "${CRAFT_SERVER_DIR}/${server_name}"
  pipe=command-pipe
  exec 8<>$pipe

  if [ $PID ]; then
    if [ -p $pipe ]; then
      echo "${tty_cyan}"
      echo save-all >>$pipe
      echo stop >>$pipe
      i=0
      until [ $i -gt 15 ]; do
        while read -r line; do
          if [[ "$line" == *"All dimensions are saved"* ]]; then
            echo "${tty_reset}"
            break 2
          fi
        done <"${CRAFT_SERVER_DIR}/${server_name}/logs/latest.log"
        ((i = i + 1))
        sleep 1
      done
      if [ $i -gt 15 ]; then
        echo "${tty_reset}"
        warn "Unable to run save-all and stop. Some game data may have been lost"
        kill -9 $PID
      fi
    else
      echo "${tty_reset}"
      warn "Unable to run save-all and stop. Some game data may have been lost"
      kill -9 $PID
    fi
  fi

  fwhip "\"${server_name}\" Minecraft server stopped"
  echo "$(date) : Stop: \"${server_name}\" stopped" >>"${CRAFT_SERVER_DIR}/${server_name}/logs/monitor/$(date '+%Y-%m').log"
  $test && echo && runtime && echo
  exit 0

}
