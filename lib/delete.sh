#!/usr/bin/env bash

command="delete"
server_name=false
test=false

delete_command () {

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

  delete_server

}

delete_server () {

  if [ -d "${CRAFT_SERVER_DIR}/${server_name}" ]; then
    warn "Are you sure you want to permanently delete \"${server_name}?\""
    read -p "(y/n) : " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
      fwhip "Deleting dir: ${CRAFT_SERVER_DIR}/${server_name// /\ }"
      execute "rm" "-r" "${CRAFT_SERVER_DIR}/${server_name}"
    else 
      fwhip "Cancelled"
    fi
  else 
    warn "\"${server_name}\" does not exist in ${CRAFT_SERVER_DIR}"
    $test && echo && runtime && echo
    exit 1
  fi

  $test && echo && runtime && echo
  exit 0

}