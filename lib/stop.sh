#!/bin/bash

command="stop"
server_name=false

. "${craft_home_dir}/lib/common.sh"

stop_server () {

  get_properties 

  PID=$(netstat -vanp tcp | grep $server_port | awk '{print $9}')

  if [ "$PID" == "" ]; then
    warn "No server running on port: ${server_port}"
    ohai "Force stopping all related processes ... just in case"
  else 
    ohai "Stopping ${server_name} Minecraft server"
  fi

  #write out current crontab
  crontab -l > $craft_server_dir/.crontab
  #echo new cron into cron file
  sed -i ".bak" "/${server_name}/d" $craft_server_dir/.crontab
  #install new cron file
  crontab $craft_server_dir/.crontab && rm $craft_server_dir/.crontab

screen -S $server_name -p 0 -X stuff "/stop
" &> /dev/null

  ohai "${server_name} Minecraft server stopped"
  echo "$(date) : Stop: ${server_name} stopped" >> $craft_server_dir/$server_name/logs/monitor/$(date '+%Y-%m').log

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

  if [ "${server_name}" == false ] ; then
    missing_required_option "$command" "-n"
    exit 1
  fi

  find_server ${server_name}

  stop_server

}