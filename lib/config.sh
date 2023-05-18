#!/bin/bash

command="config"
server_name=false

. "${craft_home_dir}/lib/common.sh"

read_properties () {

  properties="${1}"

  # Read server.properties
  count=0
  while IFS="" read -r line || [ -n "$line" ]; do
    if [[ $count -gt 1 ]]; then
      set="${line##*=}"
      read -p "${line%=*} (Set to: \"${set}\"): " input </dev/tty
      if [ "$input" != "" ]; then
        echo "${line%=*}=${input}" >> ${properties}.tmp
      else 
        echo "${line}" >> ${properties}.tmp
      fi
    fi
    (( count++ ))
  done < ${properties}

  # Write modified properties
  cp ${properties}.tmp ${properties}
  rm ${properties}.tmp

}

config_server () {

  server_properties="${craft_server_dir}/${server_name}/server.properties"
  launcher_properties="${craft_server_dir}/${server_name}/fabric-server-launcher.properties"

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

}

config_command () {

  [ ! -n "$1" ] && command_help "$command" 

	while getopts ":n:sh" opt; do
    case $opt in 
      n)
        server_name="$OPTARG"
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

  if [ "${server_name}" == false ] ; then
    missing_required_option "$command" "-n"
    exit 1
  fi

  find_server ${server_name}

  config_server

}