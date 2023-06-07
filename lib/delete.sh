#!/usr/bin/env bash

command="delete"
server_name=false
test=true

delete_server () {

  if [ -d "${CRAFT_SERVER_DIR}/${server_name}" ]; then
    warn "Are you sure you want to permanently delete ${server_name}?"
    read -p "(y/n) : " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
      ohai "Deleting dir: ${CRAFT_SERVER_DIR}/${server_name}"
      rm -r ${CRAFT_SERVER_DIR}/${server_name}
    else 
      ohai "Cancelled"
    fi
  else 
    warn "${server_name} does not exist in ${CRAFT_SERVER_DIR}"
    exit 1
  fi

  exit 0

}

delete_command () {

  [ ! -n "$1" ] && command_help "$command" 1

	while getopts ":n:ht" opt; do
    case $opt in 
      n ) server_name="$OPTARG" ;;
      h ) command_help "$command" 0 ;;
      t ) test=true ;;
      : ) missing_argument "$command" "$OPTARG" ;;
      * ) invalid_option "$command" "$OPTARG" ;;
    esac
  done

  if [ "${server_name}" == false ] ; then
    missing_required_option "$command" "-n"
  fi

  find_server ${server_name}

  if [[ "$test" == true ]]; then
    echo "command                 : $command        "
    echo "server_name             : $server_name    "
    echo "test                    : $test           "
  fi

  delete_server

}