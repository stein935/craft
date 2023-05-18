#!/bin/bash

command="status"
server_name=false

. "${craft_home_dir}/lib/common.sh"

server_status () {

  get_properties
  
  PID=$(netstat -vanp tcp | grep $server_port | awk '{print $9}')
  if [ "$PID" != "" ]; then
    ohai "${server_name} Minecraft server running on port: ${server_port} PID: ${PID}"
  else
    warn "${server_name} is not running"
  fi

}

  status_command () {

  [ ! -n "$1" ] && command_help "$command"

  while getopts ":n:c:h" opt; do
    case $opt in 
      n)
        server_name="$OPTARG"
        ;;
      h)
        command_help "$command"
        exit 0
        ;;
      :)
        missing_argument "$command" "$OPTARG"
        exit 1
        ;;
      *)
        invalid_option "$command" "$OPTARG"
        exit 1
        ;;
    esac
  done

  if [[ "${server_name}" == false && "${server_command}" == false ]] ; then
    missing_required_option "$command" "-n"
    exit 1
  fi

  find_server ${server_name}

  server_status

}