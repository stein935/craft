#!/bin/bash

# variables

command=$1;

# # find PID
# PID=$(lsof -i -P | grep ':25565 (LISTEN)' | awk '{print $2}')

# # running message 
# running="echo $server running on $PID"

# # not running message
# not_running="echo $server not running"

# # start 
# start="source ~/MinecraftServers/scripts/start.sh $server"

# # stop
# stop="source ~/MinecraftServers/scripts/stop.sh $server"

start () { source ~/MinecraftServers/scripts/start.sh $1 ;}

usage () { echo "Usage: craft $command [ -s SERVER ] [ -h ]" >&2 ;}


# commands

# start 
# $ craft start
if [ "$command" == "start" ]; then
  unset -v s
  unset -v h
  shift
  while getopts "hs:" opt; do
    case $opt in 
      h)  
        h=1
        usage
        exit
        ;;
      s)
        s=1
        start "$OPTARG"
        ;;
      :)
        usage
        ;;
      *)
        usage
        exit 1
        ;;
    esac
  done
  shift "$(( OPTIND - 1 ))"
  if ! [ "$h" ] || [ "$s" ]; then
    echo "reqs"
  fi
elif [ "$command" == "install" ]; then
  echo "Install"
  if ! [ -d "/usr/local/bin/craft" ]; then
    pwd=$(pwd)
    cp -r $pwd /usr/local/bin/craft
    sudo chmod -R 755 /usr/local/bin/craft
  else 
    echo "Craft is already installed"
    echo "Run \`craft uninstall\` to uninstall Craft"
  fi
elif [ "$command" == "uninstall" ]; then
  echo "Uninstall"
  if [ -d "/usr/local/bin/craft" ]; then
    rm -r /usr/local/bin/craft
  else 
    echo "Craft is not installed"
    echo "Run \`craft install\` to install Craft"
  fi
fi

# # stop 
# # $ craft stop  
# elif [ "$command" == "stop" ]; then
#   if [ "$PID" != "" ]; then
#     $stop
#   else
#     $not_running
#   fi

# # status
# # $ craft status
# elif [ "$command" == "status" ]; then
#   if [ "$PID" != "" ]; then
#     $running
#   else 
#     $not_running
#   fi

# # server
# # $ craft server  
# elif [ "$command" == "server" ]; then
#   if [ "$PID" != "" ]; then
#     screen -r
#   else 
#     $not_running
#   fi

# # restart
# # $ craft restart  
# elif [ "$command" == "restart" ]; then
#   $stop & 
#   wait
#   $start

# # init
# # $ craft restart  
# elif [ "$command" == "restart" ]; then
#   $stop & 
#   wait
#   $start
# else 
#   echo "Command not recognized: $command"
# fi
