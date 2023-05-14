#!/bin/bash

command="start"
sever_init_mem="512"
server_max_mem="8"

. "${craft_home_dir}/lib/common.sh"

start_server () {

  ohai "Starting ${server_name} Minecraft server"

  if [[ -f "${craft_server_dir}/${server_name}/logo.txt" ]]; then 
    cat "${craft_server_dir}/${server_name}/logo.txt"
  fi
    
  cd "${craft_server_dir}/${server_name}"

  java -Xms${server_init_mem}M -Xmx${server_max_mem}G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true fabric-server-launch.jar nogui

  # screen -AmdS "$server_name" java -jar -Xmx${server_max_mem}G fabric-server-launch.jar nogui

  while [ 1 ]
  do
    PID=$(netstat -vanp tcp | grep 25565 | awk '{print $9}')
    if [ "$PID" != "" ]; then
      ohai "${server_name} Minecraft server running on PID: $PID"
      return
    fi
    sleep 1
  done

}

start_command () {

  [ ! -n "$1" ] && command_help "$command"

  while getopts ":n:m:h" opt; do
    case $opt in 
      n)
        server_name="$OPTARG"
        ;;
      m)
        server_mem="$OPTARG"
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

  start_server

}
