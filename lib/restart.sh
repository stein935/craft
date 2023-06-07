#!/usr/bin/env bash

command="server"
server_name=false
test=false

restart_server () {

  get_properties
  
  craft stop -fn $server_name &
  wait
  craft start -mn $server_name &
  wait
  echo "$(date) : Restart: ${server_name} was restarted." >> $CRAFT_SERVER_DIR/$server_name/logs/monitor/$(date '+%Y-%m').log

  exit 0

}

restart_command () {

  [ ! -n "$1" ] && command_help "$command" 1

  while getopts ":n:ht" opt; do
    case $opt in 
      n ) server_name="$OPTARG" ;;
      h ) command_help "$command" 0 ;;
      t ) test=true ;;
      : ) missing_argument "$command" "$OPTARG" ;;
      * ) invalid_option "$command" "$OPTARG" ;;
    esac
  done

  if [[ "${server_name}" == false && "${server_command}" == false ]] ; then
    missing_required_option "$command" "-n"
  fi

  find_server ${server_name}

  if [[ "$test" == true ]]; then
    echo "command                 : $command        "
    echo "server_name             : $server_name    "
    echo "test                    : $test           "
  fi

  restart_server

}