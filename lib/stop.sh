#!/usr/bin/env bash

command="stop"
server_name=false
force=false
test=false

stop_server () {

  get_properties 

  PID=$(netstat -vanp tcp | grep $server_port | awk '{print $9}')
  SCREEN=($(screen -ls | grep $server_name | awk '{print $1}'))

  if [ -z "$PID" ]; then
    warn "No server running on port: ${server_port}"
    $force && ohai "Force stopping all related processes ... just in case" || $(printf '  %s\n    %s\n' "To force stop run:" "craft stop -fn ${server_name}"; exit 1)
  else 
    ohai "Stopping ${server_name} Minecraft server"
  fi

  # Remove monitoring cron job
  crontab -l > $CRAFT_SERVER_DIR/.crontab
  sed -i ".bak" "/${server_name}/d" $CRAFT_SERVER_DIR/.crontab
  crontab $CRAFT_SERVER_DIR/.crontab && rm $CRAFT_SERVER_DIR/.crontab

  for ((i = 0; i < ${#SCREEN[@]}; i++)); do
    echo "${SCREEN[$i]}"
    screen -S ${SCREEN[$i]} -p 0 -X stuff "/stop
" 
    screen -X -S ${SCREEN[$i]} quit    
  done
  screen -wipe &> /dev/null
  [ -n "$PID" ] && kill -9 $PID

  $0 status -n $server_name
  ohai "${server_name} Minecraft server stopped"
  echo "$(date) : Stop: ${server_name} stopped" >> $CRAFT_SERVER_DIR/$server_name/logs/monitor/$(date '+%Y-%m').log

  exit 0

}

stop_command () {

  [ -z "$1" ] && command_help "$command" 1

  while getopts ":n:fht" opt; do
    case $opt in 
      n ) server_name="$OPTARG" ;;
      f ) force=true ;;
      h ) command_help "$command" 0 ;;
      t ) test=true ;;
      : ) missing_argument "$command" "$OPTARG" ;;
      * ) invalid_option "$command" "$OPTARG" ;;
    esac
  done

  if [ "${server_name}" == false ] ; then
    missing_required_option "$command" "-n"
  fi

  find_server ${server_name}

  if [[ "$test" == true ]]; then
    echo "command                 : $command        "
    echo "server_name             : $server_name    "
    echo "force                   : $force          "
    echo "test                    : $test           "
  fi

  stop_server

}