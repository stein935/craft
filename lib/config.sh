#!/usr/bin/env bash

command="config"
server_name=false
test=false

read_properties () {

  properties="${1}"

  # Read server.properties
  count=0
  while IFS="" read -r line || [ -n "$line" ]; do
    if [[ $count -gt 1 ]]; then
      set="${line##*=}"
      read -p "${line%=*} (Set to: \"${set}\"): " input </dev/tty
      if [ "$input" != "" ]; then
        input=$(printf '%s\n' "${input}")
        echo "${line%=*}=${input}" >> ${properties}.tmp
        echo "$(date) : Config: ${server_name} setting ${line%=*} changed from \"${set}\" to \"${input}\"" >> $CRAFT_SERVER_DIR/$server_name/logs/monitor/$(date '+%Y-%m').log
      else 
        echo "${line}" >> ${properties}.tmp
      fi
    fi
    (( count++ ))
  done < ${properties}

  # Write modified properties
  cp ${properties}.tmp ${properties}
  rm ${properties}.tmp

  exit 0

}

config_server () {

  server_properties="${CRAFT_SERVER_DIR}/${server_name}/server.properties"
  launcher_properties="${CRAFT_SERVER_DIR}/${server_name}/fabric-server-launcher.properties"

  ### Server Properties

  # Start collecting server properties
  ohai "Minecraft server properties"

  # server.properties header
  echo "#Minecraft server properties" >> ${server_properties}.tmp
  echo "#$(date)" >> ${server_properties}.tmp

  # Read server.properties
  read_properties ${server_properties}


  ### Launcher Properties

  # Start collecting launcher properties 
  ohai "Minecraft launcher properties"

  # fabric-server-launcher.properties header
  echo "#Fabric launcher properties" >> ${launcher_properties}.tmp
  echo "#$(date)" >> ${launcher_properties}.tmp

  # Read fabric-server-launcher.properties
  read_properties ${launcher_properties}

  while true; do

    ohai "Do you want to add a text art logo to ${server_name}?"
    read -p "(y/n) : " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then

      read -p "Path to file : " input
      input=$(echo $input | tr -d '~')
      cp "${HOME}${input}" $CRAFT_SERVER_DIR/$server_name/logo.txt
      break

    elif [[ $REPLY =~ ^[Nn]$ ]]; then

      break

    else

      echo "Please enter y or n"

    fi

  done

  ohai "Configuration complete"

}

config_command () {

  [ -z "$1" ] && command_help "$command" 1

  while getopts ":n:ht" opt; do
    case $opt in 
      n ) server_name="$OPTARG" ;;
      h ) command_help "$command" 0 ;;
      t ) test=true ;;
      : ) missing_argument "$command" "$OPTARG" ;;
      * ) invalid_option "$command" "$OPTARG" ;;
    esac
  done

  [[ ${server_name} == false ]] && missing_required_option "$command" "-n"

  find_server ${server_name}

  if [[ "$test" == true ]]; then
    echo "command                 : $command        "
    echo "server_name             : $server_name    "
    echo "test                    : $test           "
  fi

  config_server

}