#!/bin/bash

command="delete"
server_name=false

. "${craft_home_dir}/lib/common.sh"

delete_server () {

  if [ -d "${craft_server_dir}/${server_name}" ]; then
    warn "Are you sure you want to permanently delete ${server_name}?"
    read -p "(y/n) : " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
      ohai "Deleting dir: ${craft_server_dir}/${server_name}"
      rm -r ${craft_server_dir}/${server_name}
    else 
      ohai "Cancelled"
    fi
  else 
    warn "${server_name} does not exist in ${craft_server_dir}"
    exit 1
  fi

}

delete_command () {

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

  delete_server

}