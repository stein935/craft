#!/bin/bash
set -u

create_server_dir () {

	while getopts ":n:" opt; do
    case $opt in 
      -n)  
        echo "$@"
        ;;
      :)
        echo "$1 Needs name"
        exit 1
        ;;
      *)
        echo "Unregognized command: $1"
        exit 1
        ;;
    esac
  done

	# mkdir "$HOME/craft_servers/$1"
	# java -jar "../config/fabric-installer.jar server" -dir "$HOME/craft_servers/$1" -downloadMinecraft
}
