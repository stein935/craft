#!/bin/bash

command="command"
server_command=false
server_name=false

. "${craft_home_dir}/lib/common.sh"

command_server () {
  
  PID=$(netstat -vanp tcp | grep 25565 | awk '{print $9}')
  if [ "$PID" != "" ]; then

    ohai "Sending ${server_command} to ${server_name} Minecraft server"

screen -S "$server_name" -p 0 -X stuff "${server_command}
"
    echo "${tty_bold}Server logs${tty_reset}:"

    tail ${craft_server_dir}/${server_name}/logs/latest.log

    > "${craft_server_dir}/${server_name}/logs/latest.log"

  else
    warn "${server_name} is not running"
  fi

}

command_command () {

  [ ! -n "$1" ] && command_help "$command"

  while getopts ":n:c:h" opt; do
    case $opt in 
      n)
        server_name="$OPTARG"
        ;;
      c)
        server_command="$OPTARG"
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
    missing_required_option "$command" "-n and -c"
    exit 1
  fi

  command_server

}