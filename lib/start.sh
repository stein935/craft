#!/usr/bin/env bash

command="start"
server_name=false
monitor=false
server_init_mem="512M"
server_max_mem="8G"
quiet=true
frequency="5"
test=false

start_command() {

  [ -z "$1" ] && command_help "$command" 1

  while getopts ":n:f:mvht" opt; do
    case $opt in
    n) server_name="$OPTARG" ;;
    f) monitor=true frequency="$OPTARG" ;;
    m) monitor=true ;;
    v) quiet=false ;;
    h) command_help "$command" 0 ;;
    t) test=true ;;
    :) missing_argument "$command" "$OPTARG" ;;
    *) invalid_option "$command" "$OPTARG" ;;
    esac
  done

  [[ ${server_name} == false ]] && missing_required_option "$command" "-n"

  find_server "${server_name}"

  get_properties

  if $test; then
    echo "${tty_yellow}"
    indent "command                 : $command        "
    indent "server_name             : $server_name    "
    indent "monitor                 : $monitor        "
    indent "server_init_mem         : $server_init_mem"
    indent "server_max_mem          : $server_max_mem "
    indent "quiet                   : $quiet          "
    indent "frequency               : $frequency      "
    indent "test                    : $test           "
    echo "${tty_reset}"
  fi

  start_server

}

start_server() {

  # Check if a server is already running on the port
  pids
  screens

  if [ ${#PIDS[@]} -gt 0 ]; then
    warn "A server is already running on port: ${server_port} PID: ${PID[@]}"
    echo
    indent "Run:"
    indent "craft stop -n \"${server_name}\" or $ craft restart -n \"${server_name}\"" "6"
    echo
    $test && runtime && echo
    exit 1
  fi

  if [ ${#SCREENS[@]} -gt 0 ]; then
    warn "Quiting ${#SCREENS[@]} existing screens named \"${server_name}\""
    for screen in "${SCREENS[@]}"; do
      execute "screen" "-S" "${screen[@]}" "-X" "quit"
    done
  fi

  # Message that the server is starting
  fwhip "Starting \"${server_name}\" Minecraft server"

  if [ -f "${CRAFT_SERVER_DIR}/${server_name}/logo.txt" ]; then
    execute "cat" "${CRAFT_SERVER_DIR}/${server_name}/logo.txt"
    echo
  fi

  # Start the server
  cd "${CRAFT_SERVER_DIR}/${server_name}"
  # while true; do
  #   screen -ls | grep -q "Detached" && break
  #   sleep 1
  # done
  screen java -jar -Xms${server_init_mem} -Xmx${server_max_mem} fabric-server-launch.jar --nogui

  # Wait for server to start
  # while [ 1 ]; do
  #   pids
  #   screens
  #   if [ ${#SCREENS[@]} -gt 0 ] && [ ${#PIDS[@]} -gt 0 ]; then

  #     # Do this if the server is running
  #     fwhip "\"${server_name}\" Minecraft server running on port: ${server_port} PID: ${PIDS[*]}"
  #     echo "$(date) : Start: \"${server_name}\" running on port: ${server_port} PID: ${PIDS[*]}" >>"${CRAFT_SERVER_DIR}/${server_name}/logs/monitor/$(date '+%Y-%m').log"

  #     if $monitor; then

  #       daemon_path="/Library/LaunchDaemons/craft.${server_name// /}.daemon.plist"
  #       log_path=$(printf '%s\n' "${CRAFT_SERVER_DIR}/${server_name}/logs/daemon.log" | sed -e 's/[\/&]/\\&/g')

  #       if [ -f "/Library/LaunchDaemons/craft.${server_name// /}.daemon.plist" ]; then
  #         sudo rm -f /Library/LaunchDaemons/craft.${server_name// /}.daemon.plist
  #       fi

  #       sudo cp "${CRAFT_HOME_DIR}/config/craft.servername.daemon.plist" $daemon_path

  #       sudo sed -i '' "s/_servername_/${server_name// /}/g" $daemon_path
  #       sudo sed -i '' "s/_server_name_/${server_name// /\ }/g" $daemon_path
  #       sudo sed -i '' "s/_log_path_/${log_path}/g" $daemon_path
  #       sudo sed -i '' "s/_user_/${USER}/g" $daemon_path

  #       if [ ! -f "${CRAFT_SERVER_DIR}/${server_name}/logs/daemon.log" ]; then execute "touch" "${CRAFT_SERVER_DIR}/${server_name}/logs/daemon.log"; fi

  #       ! sudo launchctl list | grep "craft.${server_name// /}.daemon" &>/dev/null && sudo launchctl load $daemon_path

  #     fi
  #     $test && echo && runtime && echo
  #     exit 0
  #   fi
  #   sleep 1
  # done

}
