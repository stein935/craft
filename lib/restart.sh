#!/bin/bash

command="server"
server_name=false

. "${craft_home_dir}/lib/common.sh"

restart_server () {

  get_properties
  
  craft stop -n $server_name
  craft start -n $server_name -m
  echo "$(date) : Restart: ${server_name} was restarted." >> $craft_server_dir/$server_name/logs/monitor/$(date '+%Y-%m').log


}

  restart_command () {

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

  if [[ "${server_name}" == false && "${server_command}" == false ]] ; then
    missing_required_option "$command" "-n"
    exit 1
  fi

  find_server ${server_name}

  restart_server

}