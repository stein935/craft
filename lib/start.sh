#!/bin/bash

command="start"
server_name=false
monitor=false
server_init_mem="512"
server_max_mem="8"
quiet=true
frequency="1"

. "${craft_home_dir}/lib/common.sh"

start_server () {

  # Load server properties
  get_properties

  # Check if a server is already running on the port
  PID=$(netstat -vanp tcp | grep $server_port | awk '{print $9}')

  if [ "$PID" != "" ]; then
    warn "A server is already running on port: ${server_port}. PID: ${PID}
    Run $ craft stop -n ${server_name} or $ craft restart -n ${server_name}"
    exit 1
  fi

  # Message that the server is starting
  ohai "Starting ${server_name} Minecraft server"

  if [ -f "${craft_server_dir}/${server_name}/logo.txt" ]; then 
    cat "${craft_server_dir}/${server_name}/logo.txt"
    echo
  fi

  # Kill screens or processes that might be duplicates
  for session in $(screen -ls | grep -o "[0-9]*\.${server_name}")
  do 
    screen -S "${session}" -X quit 
  done
  for pid in $PID; do
    kill -9 "$pid" 
    # &> /dev/null
  done


  # Start the server
  cd ${craft_server_dir}/${server_name}

  if [ "$quiet" == true ]; then
    screen -AmdLS "$server_name" java -jar -Xms$server_init_mem -Xmx$server_max_mem fabric-server-launch.jar --nogui
  else
    java -jar -Xms$server_init_mem -Xmx$server_max_mem fabric-server-launch.jar --nogui
  fi

  # Wait for server to start
  while [ 1 ]
  do
    SCREEN=$(screen -ls $server_name)
    PID=$(netstat -vanp tcp | grep $server_port | awk '{print $9}')

    if [[ "$SCREEN" != "" && "$quiet" == true && "$PID" != "" ]]; then

      # Do this if the server is running
      ohai "${server_name} Minecraft server running on port: ${server_port} PID: ${PID}"
      echo "$(date) : Start: ${server_name} running on port: ${server_port} PID: ${PID}" >> $craft_server_dir/$server_name/logs/monitor/$(date '+%Y-%m').log

      if [[ "$monitor" == true ]]; then
        
        # Set server minitor cron job 
        crontab -l > $craft_server_dir/.crontab
        echo "*/${frequency} * * * * /usr/local/craft/lib/monitor.sh $server_name" >> $craft_server_dir/.crontab
        crontab $craft_server_dir/.crontab && rm $craft_server_dir/.crontab

      fi 
      return

    elif [[ "$SCREEN" == "" && "$quiet" == true ]]; then

      # Sever failed to start
      warn "Failed to start ${server_name}"
      echo "To see server logs run: cat -n ${craft_server_dir}/${server_name}/logs/latest.log"
      exit 1
    fi
    sleep 1
  done

}

start_command () {

  [ ! -n "$1" ] && command_help "$command"

  while getopts ":n:mvh" opt; do
    case $opt in 
      n)
        server_name="$OPTARG"
        ;;
      m)
        monitor=true
        eval nextopt=\${$OPTIND}
        if [[ -n $nextopt && $nextopt != -* ]] ; then
          frequency=$nextopt
        fi
        if [[ -n $frequency && ! $frequency =~ ^[0-9]+$ ]]; then
          echo "Frequency parameter passed to -m must be an integer (minutes)."
          exit
        fi
        ;;
      v)
        quiet=false
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
