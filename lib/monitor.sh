#!/usr/bin/env bash
PATH=/usr/local/bin:/usr/local/sbin:~/bin:/usr/bin:/bin:/usr/sbin:/sbin

command="monitor"
server_name=false
test=false

monitor_command() {

  [ -z "$1" ] && command_help "$command" 1

  while getopts ":n:ht" opt; do
    case $opt in
    n) server_name="$OPTARG" ;;
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
    indent "test                    : $test           "
    echo "${tty_reset}"
  fi

  monitor_server

}

monitor_server() {

  if server_status &>/dev/null; then
    $test && runtime && echo
    exit 0
  else
    execute "$0" "restart" "-mn" "${server_name}"
    echo "$(date) : Monitor: \"${server_name}\" was restarted automatically when a crash was detected. Port: ${server_port} PID: ${PIDS[@]}" >>"${CRAFT_SERVER_DIR}/${server_name}/logs/monitor/$(date '+%Y-%m').log"
    if [ -n "$discord_webhook" ]; then
      discord_message "Auto Restart" "\"${server_name}\" was restarted automatically when a crash was detected" "12745742" "Server Monitor"
    fi
    $test && echo && runtime && echo
    exit 1
  fi
}
