#!/usr/bin/env bash

command="mod"
server_name=false
file=false
list=false
remove=false
test=false

mod_command() {

  [ -z "$1" ] && command_help "$command" 1

  while getopts ":n:p:r:lth" opt; do
    case $opt in
    n) server_name="$OPTARG" ;;
    p) file="$OPTARG" ;;
    l) list=true ;;
    r) remove="$OPTARG" ;;
    h) command_help "$command" 0 ;;
    t) test=true ;;
    :) missing_argument "$command" "$OPTARG" ;;
    *) invalid_option "$command" "$OPTARG" ;;
    esac
  done

  [[ "${server_name}" == false ]] && missing_required_option "$command" "-n"

  find_server "${server_name}"

  if $test; then
    echo "${tty_yellow}"
    indent "command                 : $command        "
    indent "server_name             : $server_name    "
    indent "file                    : $file           "
    indent "list                    : $list           "
    indent "remove                  : $remove         "
    indent "test                    : $test           "
    echo "${tty_reset}"
  fi

  mod_server

}

mod_server() {

  $list && ls "${CRAFT_SERVER_DIR}/${server_name}/mods" | cat -n

  if [[ "${remove}" != false ]]; then
    execute "rm" "-f" "${CRAFT_SERVER_DIR}/$server_name/mods/${remove}"
    fwhip "${remove} removed from \"${server_name}\" Minecraft server"
    echo "$(date) : Mod: Removed ${remove} from \"${server_name}\"" >>"${CRAFT_SERVER_DIR}/${server_name}/logs/monitor/$(date '+%Y-%m').log"
  fi

  if [[ "${file}" != false ]]; then
    execute "cp" "${file}" "${CRAFT_SERVER_DIR}/${server_name}/mods"
    fwhip "${file} installed on \"${server_name}\" Minecraft server"
    echo "$(date) : Mod: Added ${file} to \"${server_name}\"" >>"${CRAFT_SERVER_DIR}/${server_name}/logs/monitor/$(date '+%Y-%m').log"
  fi

  $test && echo && runtime && echo
  exit 0

}
