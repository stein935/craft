#!/bin/bash
PATH=/usr/local/bin:/usr/local/sbin:~/bin:/usr/bin:/bin:/usr/sbin:/sbin

craft_server_dir="$HOME/Craft" 
craft_home_dir="/usr/local/craft"
server_name=$1
. "${craft_home_dir}/lib/common.sh"

get_properties

if ! [[ -d "$craft_server_dir/$server_name/logs/monitor" ]]; then
  mkdir $craft_server_dir/$server_name/logs/monitor
fi

PID=$(netstat -vanp tcp | grep $server_port | awk '{print $9}')

if [ "$PID" != "" ]; then
	status="running on ${PID}"

  echo "$(date) : ${server_name} running" >> $craft_server_dir/$server_name/logs/monitor/$(date '+%Y-%m').log
else
  status="restarting"  

  echo "$(date) : ${server_name} restarted" >> $craft_server_dir/$server_name/logs/monitor/$(date '+%Y-%m').log
  craft restart -n $server_name
fi

# message=$(printf 'tell Application "Finder" to say "%s is %s"' "$server_name" "$status")
# osascript -l AppleScript -e "$message"
