#!/usr/bin/env bash

command="command"
server_command=false
server_name=false
test=false

command_server () {
  get_properties
  PID=$(netstat -vanp tcp | grep $server_port | awk '{print $9}')
  if [ -n "$PID" ]; then
    ohai "Sending \"${server_command}\" to ${server_name} Minecraft server"
    cat ${CRAFT_SERVER_DIR}/${server_name}/logs/latest.log > ${CRAFT_SERVER_DIR}/${server_name}/logs/latest.log.tmp
screen -S "$server_name" -p 0 -X stuff "${server_command} 
" & 
  wait
  else
    warn "${server_name} is not running"
  fi

  while [ 1 ]; do
    compare=$(comm -23 ${CRAFT_SERVER_DIR}/${server_name}/logs/latest.log ${CRAFT_SERVER_DIR}/${server_name}/logs/latest.log.tmp)
    if [ -n "$compare" ]; then
      echo "${tty_bold}Server logs${tty_reset}:"
      echo "$compare"
      echo "$(date) : Command: ${server_command} sent to ${server_name}. Server log: ${compare}" >> $CRAFT_SERVER_DIR/$server_name/logs/monitor/$(date '+%Y-%m').log
      rm ${CRAFT_SERVER_DIR}/${server_name}/logs/latest.log.tmp
      return
    fi
    sleep 1
  done

  exit 0
}

command_command () {

  [ -z "$1" ] && command_help "$command" 1

  while getopts ":n:c:th" opt; do
    case $opt in 
      n ) server_name="$OPTARG" ;;
      c ) server_command="$OPTARG" ;;
      h ) command_help "$command" 0 ;;
      t ) test=true ;;
      : ) missing_argument "$command" "$OPTARG" ;;
      * ) invalid_option "$command" "$OPTARG" ;;
    esac
  done

  [[ $server_name == false ]] && [[ $server_command == false ]] && missing_required_option "$command" "-n and -c"

  find_server ${server_name}

  if $test; then
    echo "command                 : $command        "
    echo "server_command          : $server_command "
    echo "server_name             : $server_name    "
    echo "test                    : $test           "
  fi


  command_server

}