#!/bin/bash

command="start"
server_name=false
monitor=false
server_init_mem="512"
server_max_mem="8"

. "${craft_home_dir}/lib/common.sh"

start_server () {

  get_properties

  PID=$(netstat -vanp tcp | grep $server_port | awk '{print $9}')

  # Check if a server is already running on the port
  if [ "$PID" != "" ]; then
    warn "A server is already running on port: ${server_port}. PID: ${PID}
    Run $ craft stop -n ${server_name} or $ craft restart -n ${server_name}"
    exit 1
  fi

  ohai "Starting ${server_name} Minecraft server"

  if [ -f "${craft_server_dir}/${server_name}/logo.txt" ]; then 
    cat "${craft_server_dir}/${server_name}/logo.txt"
    echo
  fi

  cd ${craft_server_dir}/${server_name}

  screen -AmdLS "$server_name" java -jar -Xms$server_init_mem -Xmx$server_max_mem fabric-server-launch.jar --nogui

  while [ 1 ]
  do
    PID=$(netstat -vanp tcp | grep $server_port | awk '{print $9}')
    if [ "$PID" != "" ]; then
      ohai "${server_name} Minecraft server running on port: ${server_port} PID: ${PID}"

      if [[ "$monitor" == true ]]; then
        #write out current crontab
        crontab -l > $craft_server_dir/.crontab
        #echo new cron into cron file
        echo "*/15 * * * * /usr/local/craft/lib/monitor.sh $server_name" >> $craft_server_dir/.crontab
        #install new cron file
        crontab $craft_server_dir/.crontab && rm $craft_server_dir/.crontab
      fi 
      return
    fi
    sleep 1
  done

}

start_command () {

  [ ! -n "$1" ] && command_help "$command"

  while getopts ":n:mh" opt; do
    case $opt in 
      n)
        server_name="${OPTARG[@]}"
        ;;
      m)
        monitor=true
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

  start_server

}
