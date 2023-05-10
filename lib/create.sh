#!/bin/bash

create_help () {
  echo "
Command: create

Usage: 
  craft create -n <server_name> [options]

Options
  -n

"
  exit 1
}

missing_argument () {
  echo "
Missing argument: \"$1\" requires an argument"
  create_help
}

unrecognized_flag () {
  echo "
Unrecognized flag: \"$1\""
  create_help
}

create_server () {

  [ ! -n "$1" ] && create_help

  server_name=""
  minecraft_version=""

	while getopts ":n:" opt; do
    case $opt in 
      n)  
        shift
        server_name="$OPTARG"
        ;;
      :)
        missing_argument $1
        exit 1
        ;;
      *)
        unrecognized_flag $1
        exit 1
        ;;
    esac
  done

	
}

# mkdir "$HOME/craft_servers/$1"
# java -jar "../config/fabric-installer.jar server" -dir "$HOME/craft_servers/$1" -downloadMinecraft