#!/usr/bin/env bash
PATH=/usr/local/bin:/usr/local/sbin:~/bin:/usr/bin:/bin:/usr/sbin:/sbin

command="monitor"
server_name=false
players=false
test=false

monitor_command() {

  [ -z "$1" ] && command_help "$command" 1

  while getopts ":n:hpt" opt; do
    case $opt in
    n) server_name="$OPTARG" ;;
    h) command_help "$command" 0 ;;
    p) players=true ;;
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
    indent "players                 : $players        "
    indent "test                    : $test           "
    echo "${tty_reset}"
  fi

  monitor_server

}

monitor_server() {

  if server_status &>/dev/null; then

    if $players; then
      players_file="${CRAFT_SERVER_DIR}/${server_name}/players.txt"
      [ -f "$players_file" ] || touch "$players_file"
      old="$(cat "$players_file")"
      new=()
      list=$(execute "$0" "command" "-pn" "${server_name}" "-c" "list")
      list="${list##*online: }"
      list="${list//,/}"

      for new_player in $list; do
        if ! [[ ${old} =~ $new_player ]]; then
          new+=("$new_player")
        fi
      done

      if [ ${#new[@]} -gt 0 ]; then
        for player in ${new[@]}; do
          if [ -n "$discord_webhook" ]; then
            discord_message "${player} Joined" "${player} joined ${server_name}" "3447003" "Server Monitor"
          fi
        done
      fi

      echo "$list" >"$players_file"
    fi

    $test && runtime && echo
    exit 0
  else
    execute "$0" "restart" "-mn" "${server_name}"
    pid
    echo "$(date) : Monitor: \"${server_name}\" was restarted automatically when a crash was detected. Port: ${server_port} PID: ${PID}" >>"${CRAFT_SERVER_DIR}/${server_name}/logs/monitor/$(date '+%Y-%m').log"
    if [ -n "$discord_webhook" ]; then
      discord_message "Auto Restart" "${server_name} was restarted automatically when a crash was detected" "12745742" "Server Monitor"
    fi
    execute "$0" "status" "-n" "${server_name}"
    $test && echo && runtime && echo
    exit 1
  fi
}
