#!/bin/bash
PATH=/usr/local/bin:/usr/local/sbin:~/bin:/usr/bin:/bin:/usr/sbin:/sbin

craft_server_dir="$HOME/Craft" 
craft_home_dir="/usr/local/craft"
server_name=$1

. "${craft_home_dir}/lib/common.sh"

get_properties

PID=$(netstat -vanp tcp | grep $server_port | awk '{print $9}')

if [ "$PID" == "" ]; then
  craft restart -n $server_name
  echo "$(date) : Monitor: ${server_name} was restarted automatically when a crash was detected. Port: ${server_port} PID: ${PID}" >> $craft_server_dir/$server_name/logs/monitor/$(date '+%Y-%m').log
  discord_message "Auto Restart" "${server_name} was restarted automatically when a crash was detected" "12745742" "Server Monitor"
fi