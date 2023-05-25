#!/bin/bash

command="command"
server_command=false
server_name=false

. "${craft_lib}/common.sh"

command_server () {

  get_properties
  
  PID=$(netstat -vanp tcp | grep $server_port | awk '{print $9}')
  if [ "$PID" != "" ]; then

    ohai "Sending ${server_command} to ${server_name} Minecraft server"

    cat ${craft_server_dir}/${server_name}/logs/latest.log > ${craft_server_dir}/${server_name}/logs/latest.log.tmp

screen -S "$server_name" -p 0 -X stuff "${server_command}
"

  else
    warn "${server_name} is not running"
  fi

  while [ 1 ]
  do

    compare=$(comm -23 ${craft_server_dir}/${server_name}/logs/latest.log ${craft_server_dir}/${server_name}/logs/latest.log.tmp)
    if [ "$compare" != "" ]; then

      echo "${tty_bold}Server logs${tty_reset}:"
      echo "$compare"

      echo "$(date) : Command: ${server_command} sent to ${server_name}. Server log: ${compare}" >> $craft_server_dir/$server_name/logs/monitor/$(date '+%Y-%m').log

      rm ${craft_server_dir}/${server_name}/logs/latest.log.tmp

      return

    fi
    sleep 1

  done

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

  find_server ${server_name}

  command_server

}