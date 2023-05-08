#!/bin/bash

server=$1;

crontab -l > $server
echo "" > $server
crontab $server
rm $server

# find PID
PID=$(lsof -i -P | grep ':25565 (LISTEN)' | awk '{print $2}')


echo -e "
  =============================================================

     $(date) 

     Killing $server

  =============================================================
"
kill -9 $PID &
stop_process=$!
wait $stop_process
screen -r $server -X quit & 
screen_process=$!
wait $screen_process
