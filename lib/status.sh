#!/usr/bin/env bash

command="status"
server_name=false
test=false

server_status () {

  get_properties
  
  PID=$(netstat -vanp tcp | grep $server_port | awk '{print $9}')
  SCREEN=($(screen -ls | grep $server_name | awk '{print $1}'))
  if [ "$PID" != "" ]; then
    ohai "${server_name} Minecraft server running on port: ${server_port} PID: ${PID}"
    ! [[ ${#SCREEN[@]} == 1 ]] && warn "Count screen sessions named ${server_name}: ${#SCREEN[@]}"
    echo "$(date) : Status: ${server_name} is running on port: ${server_port} PID: ${PID}." >> $CRAFT_SERVER_DIR/$server_name/logs/monitor/$(date '+%Y-%m').log 
    exit 0
  else
    warn "${server_name} is not running"
    [[ ${#SCREEN[@]} -gt 0 ]] && warn "Count screen sessions named ${server_name}: ${#SCREEN[@]}"
    echo "$(date) : Status: ${server_name} is not running." >> $CRAFT_SERVER_DIR/$server_name/logs/monitor/$(date '+%Y-%m').log
    exit 1
  fi

}

status_command () {

  [ ! -n "$1" ] && command_help "$command" 1

  while getopts ":n:ht" opt; do
    case "$opt" in
      n ) server_name=${OPTARG} ;;
      h ) command_help "${command}" 0 ;;
      t ) test=true ;;
      : ) missing_argument "$command" "$OPTARG" ;;
      * ) invalid_option "$command" "$OPTARG" ;;
    esac
  done

  if [[ "${server_name}" == false ]] ; then
    missing_required_option "$command" "-n"
  fi

  find_server ${server_name}

  if [[ "$test" == true ]]; then
    echo "command                 : $command        "
    echo "server_name             : $server_name    "
    echo "test                    : $test           "
  fi

  server_status

}

