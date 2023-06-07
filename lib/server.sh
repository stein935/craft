#!/usr/bin/env bash

command="server"
server_name=false
test=false

view_server () {

  get_properties 
  
  PID=$(netstat -vanp tcp | grep $server_port | awk '{print $9}')
  if [ -n "$PID" ]; then
    screen -r ${server_name}
    echo "$(date) : Server: ${server_name} was viewed." >> $CRAFT_SERVER_DIR/$server_name/logs/monitor/$(date '+%Y-%m').log
  else
    warn "${server_name} is not running"
    exit 1
  fi

  exit 0

}

server_command () {

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

  view_server

}