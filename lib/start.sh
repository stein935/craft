#!/usr/bin/env bash

command="start"
server_name=false
monitor=false
server_init_mem="512"
server_max_mem="8"
quiet=true
frequency="5"
test=false

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

  if [ -f "${CRAFT_SERVER_DIR}/${server_name}/logo.txt" ]; then 
    cat "${CRAFT_SERVER_DIR}/${server_name}/logo.txt"
    echo
  fi

  # Kill screens or processes that might be duplicates
  for session in $(screen -ls | grep -o "[0-9]*\.${server_name}")
  do 
    screen -S "${session}" -X quit 
  done
  for pid in ${PID[@]}; do
    kill -9 "$pid" 
    # &> /dev/null
  done


  # Start the server
  cd ${CRAFT_SERVER_DIR}/${server_name}

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
      echo "$(date) : Start: ${server_name} running on port: ${server_port} PID: ${PID}" >> $CRAFT_SERVER_DIR/$server_name/logs/monitor/$(date '+%Y-%m').log

      if [[ "$monitor" == true ]]; then
        
        # Set server monitor cron job 
        crontab -l > $CRAFT_SERVER_DIR/.crontab
        echo "*/${frequency} * * * * ${0} monitor $server_name" >> $CRAFT_SERVER_DIR/.crontab
        crontab $CRAFT_SERVER_DIR/.crontab && rm $CRAFT_SERVER_DIR/.crontab

      fi 
      return

    elif [[ "$SCREEN" == "" && "$quiet" == true ]]; then

      # Sever failed to start
      warn "Failed to start ${server_name}"
      echo "To see server logs run: cat -n ${CRAFT_SERVER_DIR}/${server_name}/logs/latest.log"
      exit 1

    fi
    sleep 1
  done

  exit 0

}

start_command () {

  [ ! -n "$1" ] && command_help "$command" 1

  while getopts ":n:f:mvht" opt; do
    case $opt in 
      n ) server_name="$OPTARG" ;;
      f ) monitor=true frequency="$OPTARG" ;;
      m ) monitor=true ;;
      v ) quiet=false ;;
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
    echo "monitor                 : $monitor        "
    echo "server_init_mem         : $server_init_mem"
    echo "server_max_mem          : $server_max_mem "
    echo "quiet                   : $quiet          "
    echo "frequency               : $frequency      "
    echo "test                    : $test           "
  fi

  start_server

}
