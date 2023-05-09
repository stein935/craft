#!/bin/bash

server=$1
# find PID
PID=$(lsof -i -P | grep ':25565 (LISTEN)' | awk '{print $2}')

if [ "$PID" != "" ]; then
  exit
else
  source /Users/AaronWilliamsAudio/MinecraftServers/scripts/server-cli.sh $server restart
  echo "$server was restarted $(date)
  $server now running on $PID" | Mail -s "$server Minecraft Server Restarted - $(date)" stein935@gmail.com 
  # , aaron@aaronwilliamsaudio.com 
fi
