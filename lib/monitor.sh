#!/usr/bin/env bash
PATH=/usr/local/bin:/usr/local/sbin:~/bin:/usr/bin:/bin:/usr/sbin:/sbin

CRAFT_SERVER_DIR="$HOME/Craft" 
CRAFT_HOME_DIR="/usr/local/craft"
server_name=$1

get_properties

PID=$(netstat -vanp tcp | grep $server_port | awk '{print $9}')

if $0 status -n $server_name; then
  exit 0
else
  say "Restarting ${server_name}" &
  $0 restart -n $server_name
  echo "$(date) : Monitor: ${server_name} was restarted automatically when a crash was detected. Port: ${server_port} PID: ${PID}" >> $CRAFT_SERVER_DIR/$server_name/logs/monitor/$(date '+%Y-%m').log
  if [ -n "$discord_webhook" ]; then
    discord_message "Auto Restart" "${server_name} was restarted automatically when a crash was detected" "12745742" "Server Monitor"
  fi
  exit 1
fi