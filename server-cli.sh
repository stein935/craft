#!/bin/bash

# variables

server=$1;
command=$2;

# find PID
PID=$(lsof -i -P | grep ':25565 (LISTEN)' | awk '{print $2}')

# running message 
running="echo $server running on $PID"

# not running message
not_running="echo $server not running"

# start 
start="source /Users/AaronWilliamsAudio/MinecraftServers/scripts/start.sh $server"

# stop
stop="source /Users/AaronWilliamsAudio/MinecraftServers/scripts/stop.sh $server"



# commands

# start 
# $ craft start
if [ "$command" == "start" ]; then
  if [ "$PID" != "" ]; then
    $running
  else
    $start
  fi

# stop 
# $ craft stop  
elif [ "$command" == "stop" ]; then
  if [ "$PID" != "" ]; then
    $stop
  else
    $not_running
  fi

# status
# $ craft status
elif [ "$command" == "status" ]; then
  if [ "$PID" != "" ]; then
    $running
  else 
    $not_running
  fi

# server
# $ craft server  
elif [ "$command" == "server" ]; then
  if [ "$PID" != "" ]; then
    screen -r
  else 
    $not_running
  fi

# restart
# $ craft restart  
elif [ "$command" == "restart" ]; then
  $stop & 
  wait
  $start
else 
  echo "Command not recognized: $command"
fi
