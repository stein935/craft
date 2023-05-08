#!/bin/bash

server=$1;

#write out current crontab
crontab -l > $server
echo "" > $server
crontab $server

screen -dmS "$server"
while ! screen -ls "$server" | grep -q tached; do sleep 0.1; done

screen -S "$server" -X -p 0 stuff "cd ~/MinecraftServers/$server
"


jar=$(ls -l /Users/AaronWilliamsAudio/MinecraftServers/$server/*jar | awk '{print $9}')

if test =f "~/MinecraftServers/$server/logo.txt"; then
  cat ~/MinecraftServers/logo.txt
fi

echo -e "⠀⠀⠀⠀⠀⠀⠀
  ==============================================================

     $(date) 

     Starting $server

  ==============================================================
"
screen -S "$server" -X -p 0 stuff "java -jar -Xmx8192M $jar nogui
"

while [ 1 ]
do
  PID=$(lsof -i -P | grep ':25565 (LISTEN)' | awk '{print $2}')
  if [ "$PID" = "" ]
  then
    echo -en "\r\033[KStarting $server..."
  else
    echo -en "\r\033[K$server running on PID: $PID\n"
    # #echo new cron into cron file
    # echo "* * * * * source /Users/AaronWilliamsAudio/MinecraftServers/scripts/server-monitor.sh $server" > $server
    # #install new cron file
    # crontab $server
    # rm $server
    return
  fi
  sleep 1
done

