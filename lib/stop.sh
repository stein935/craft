#!/bin/bash

command="stop"
server_name=false

. "${craft_home_dir}/lib/common.sh"

stop_server () {

  ohai "Stopping ${server_name} Minecraft server"

screen -S "$server_name" -p 0 -X stuff "/stop
"

  while [ 1 ]
  do
    PID=$(netstat -vanp tcp | grep 25565 | awk '{print $9}')
    if [ "$PID" == "" ]; then
      ohai "${server_name} Minecraft server stopped"
      return
    fi
    sleep 1
  done
}

stop_command () {

  [ ! -n "$1" ] && command_help "$command"

  while getopts ":n:h" opt; do
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

  if [[ "${server_name}" == false ]] ; then
    missing_required_option "$command" "-n"
    exit 1
  fi

  stop_server

}