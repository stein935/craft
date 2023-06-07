#!/usr/bin/env bash

command="mod"
server_name=false
path=false
list=false
remove=false
test=false

mod_server () {

  if $remove; then
    rm -f $CRAFT_SERVER_DIR/$server_name/mods/$remove
    ohai "${remove} removed from ${server_name} Minecraft server"
    echo "$(date) : Mod: Removed ${remove} from ${server_name}" >> $CRAFT_SERVER_DIR/$server_name/logs/monitor/$(date '+%Y-%m').log
  fi

  $list && ls $CRAFT_SERVER_DIR/$server_name/mods | cat -n

  if $path; then
    cp $path $CRAFT_SERVER_DIR/$server_name/mods
    ohai "${path} installed on ${server_name} Minecraft server"
    echo "$(date) : Mod: Added ${path} to ${server_name}" >> $CRAFT_SERVER_DIR/$server_name/logs/monitor/$(date '+%Y-%m').log
  fi

  exit 0

}

mod_command () {

  [ ! -n "$1" ] && command_help "$command" 1

  while getopts ":n:p:r:lh" opt; do
    case $opt in 
      n ) server_name="$OPTARG" ;;
      p ) path="$OPTARG" ;;
      l ) list=true ;;
      r ) remove="$OPTARG" ;;
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

  if $test; then
    echo "command                 : $command        "
    echo "server_name             : $server_name    "
    echo "path                    : $path           "
    echo "list                    : $list           "
    echo "remove                  : $remove         "
    echo "test                    : $test           "
  fi

  mod_server

}