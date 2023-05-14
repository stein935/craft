#!/bin/bash

command="create"
server_name=false
minecraft_version=false
loader=false
sever_init_mem="512"
server_max_mem="8"
snapshot=false
install_command="java -jar ${craft_home_dir}/config/fabric-installer.jar server -downloadMinecraft -dir"

. "${craft_home_dir}/lib/common.sh"

echo 

add_eula () {
  ohai "Sigining ${craft_server_dir}/${server_name}/eula.txt"
  echo "eula=true" > "${craft_server_dir}/${server_name}/eula.txt"
  . "${craft_home_dir}/lib/start.sh"
  start_server
}

install_sever () {

  jar_count () { cd ${craft_server_dir}/${server_name}; ls -1 *.jar 2>/dev/null | wc -l; }

  if [ $(jar_count) == "0" ]; then 

    ohai "Installing ${server_name} server in ${craft_server_dir}/${server_name}"

    cd "$craft_server_dir"

    ${install_command} &
    wait

    if [ $? == "0" ]; then 
      add_eula
    fi

  fi

}

create_server_dir () {
  server_dir="${craft_server_dir}/${server_name}"
  if ! [[ -d "$server_dir" ]]; then 
    ohai "Creating dir: ${craft_server_dir}/${server_name}"
    mkdir "$server_dir"
  fi
  install_sever
}

create_fabric_server_install_command () {
  
  ohai "Creating ${server_name}"

  echo "
  Config: 
  Server name: ${server_name}"

  install_command="${install_command} ${server_name}"
  if [[ "${minecraft_version}" != false ]] ; then
    install_command="${install_command} -mcversion ${minecraft_version}"
    echo "  Minecraft version: ${minecraft_version}"
  fi
  if [[ "${loader}" != false ]] ; then
    install_command="${install_command} -loader ${loader}"
    echo "  Fabric loader: ${loader}"
  fi
  if [[ "${snapshot}" != false ]] ; then
    install_command="${install_command} -snapshot"
    echo "  snapshot: ${snapshot}"
  fi

  echo "
  "

  create_server_dir

}

create_command () {

  [ ! -n "$1" ] && command_help "$command" 

	while getopts ":n:v:l:i:m:sh" opt; do
    case $opt in 
      n)
        server_name="$OPTARG"
        ;;
      v)
        minecraft_version="$OPTARG"
        ;;
      l)
        loader="$OPTARG"
        ;;
      i)
        server_init_mem="$OPTARG"
        ;;
      m)
        server_max_mem="$OPTARG"
        ;;
      s)
        snapshot=true
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

  if [[ "${server_name}" == false ]] ; then
    missing_required_option "$command" "-n"
    exit 1
  fi

  create_fabric_server_install_command

}