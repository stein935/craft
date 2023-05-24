#!/bin/bash

command="mod"
server_name=false
path=false
ls=false
rm=false

. "${craft_home_dir}/lib/common.sh"

mod_server () {

  if [ "$rm" != false ]; then
    rm -f $craft_server_dir/$server_name/mods/$rm
    ohai "${rm} removed from ${server_name} Minecraft server"
    echo "$(date) : Mod: Removed ${rm} from ${server_name}" >> $craft_server_dir/$server_name/logs/monitor/$(date '+%Y-%m').log
  fi

  if [ "$ls" == true ]; then
    ls $craft_server_dir/$server_name/mods | cat -n
  fi

  if [ "$path" != false ]; then
    cp $path $craft_server_dir/$server_name/mods
    ohai "${path} installed on ${server_name} Minecraft server"
    echo "$(date) : Mod: Added ${path} to ${server_name}" >> $craft_server_dir/$server_name/logs/monitor/$(date '+%Y-%m').log
  fi

}

mod_command () {

  [ ! -n "$1" ] && command_help "$command"

  while getopts ":n:p:r:lh" opt; do
    case $opt in 
      n)
        server_name="$OPTARG"
        ;;
      p)
        path="$OPTARG"
        ;;
      l)
        ls=true
        ;;
      r)
        rm="$OPTARG"
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

  mod_server

}