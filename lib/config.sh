#!/usr/bin/env bash

command="config"
server_name=false
test=false

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

  [[ "${server_name}" == false ]] && missing_required_option "$command" "-n"

  find_server "${server_name}"

  if $test; then
    echo "${tty_yellow}"
    indent "command                 : $command        "
    indent "server_name             : $server_name    "
    indent "test                    : $test           "
    echo "${tty_reset}"
  fi

  config_server

}

function cleanup {
  [ -f "${CRAFT_SERVER_DIR}/${server_name}/server.properties.tmp" ] && rm -r "${CRAFT_SERVER_DIR}/${server_name}/server.properties.tmp"
  [ -f "${CRAFT_SERVER_DIR}/${server_name}/fabric-server-launcher.properties.tmp" ] && rm -r "${CRAFT_SERVER_DIR}/${server_name}/fabric-server-launcher.properties.tmp"
}

trap cleanup EXIT

config_server () {

  server_properties="server.properties"
  launcher_properties="fabric-server-launcher.properties"

  ### Server Properties
  fwhip "Minecraft server properties"
  echo "#Minecraft server properties" > "${server_properties}.tmp"
  echo "#$(date)" >> "${server_properties}.tmp"
  read_properties "${server_properties}"

  ### Launcher Properties
  fwhip "Minecraft launcher properties"
  echo "#Fabric launcher properties" > "${launcher_properties}.tmp"
  echo "#$(date)" >> "${launcher_properties}.tmp"
  read_properties "${launcher_properties}"

  while true; do
    fwhip "Do you want to add a text art logo to \"${server_name}?\""
    read -p "(y/n) : " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      read -p "Path to file : " ans
      ans=$(echo $ans | tr -d '~')
      cp "${HOME}${ans}" "${CRAFT_SERVER_DIR}/${server_name}/logo.txt"
      break
    elif [[ $REPLY =~ ^[Nn]$ ]]; then
      break
    else
      echo "Please enter y or n"
    fi
  done

  fwhip "Configuration complete"
  $test && echo && runtime && echo
  exit 0

}

read_properties () {

  execute "cd" "${CRAFT_SERVER_DIR}/${server_name}"

  file=$1
  properties=$(cat $file)
  OLDIFS="$IFS"
  IFS=$'\n'
  for line in $properties; do
    prop=$(echo ${line%=*} | tr -d '\n') 
    set=$(echo ${line##*=} | tr -d '\n')
    if [[ "${line:0:1}" != "#" ]]; then
      read -p "${prop} (Set to: \"${set}\"): " -n 1 -r input 
      if [[ $input != '' ]]; then
        echo "${prop}=${input}" >> "${file}.tmp"
        echo "$(date) : Config: \"${server_name}\" setting ${prop} changed from \"${set}\" to \"${input}\"" >> "${CRAFT_SERVER_DIR}/${server_name}/logs/monitor/$(date '+%Y-%m').log"
      else
        echo "${line}" >> "${file}.tmp"
      fi
    fi
  done
  IFS="$OLDIFS"

  # # Write modified properties
  execute "cp" "${file}.tmp" "${file}"
  execute "rm" "${file}.tmp"

}