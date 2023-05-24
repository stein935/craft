#!/bin/bash

command="create"
server_name=false
minecraft_version=false
loader=false
snapshot=false
install_command="java -jar ${craft_home_dir}/config/fabric-installer.jar server -downloadMinecraft -dir"

. "${craft_home_dir}/lib/common.sh"

sign_eula () {

   while true; do

    ohai "Agree to Minecraft eula for ${server_name}?"
    read -p "(y/n) : " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
    
      ohai "Sigining ${craft_server_dir}/${server_name}/eula.txt"
      sed -i '' -e '$ d' "${craft_server_dir}/${server_name}/eula.txt"
      echo "eula=true" >> ${craft_server_dir}/${server_name}/eula.txt

      break

    elif [[ $REPLY =~ ^[Nn]$ ]]; then

      warn "You will need to accept eula by editing ${craft_server_dir}/${server_name}/eula.txt 
      before you can start the server" 

      break

    else

      echo "Please enter y or n"

    fi

  done

  ohai "${server_name} has been installed!"
  echo "  Location ${craft_server_dir}/${server_name}"
  echo "  To start the server - Run:
    > craft start -n ${server_name}"

}

ask_config_server () {

  # Add initial fabric-server-properties
  echo -e "#Fabric launcher properties\n$(cat ${craft_server_dir}/${server_name}/fabric-server-launcher.properties)" > ${craft_server_dir}/${server_name}/fabric-server-launcher.properties
  echo "server_init_mem=512M" >> "${craft_server_dir}/${server_name}/fabric-server-launcher.properties"
  echo "server_max_mem=8G" >> "${craft_server_dir}/${server_name}/fabric-server-launcher.properties"
  echo "discord_webhook=" >> "${craft_server_dir}/${server_name}/fabric-server-launcher.properties"

  # Ask about custom config
  while true; do

    ohai "Do you want to configure ${server_name}?"
    read -p "(y/n) : " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then

      craft config -n "$server_name" &
      wait

      sign_eula

      break

    elif [[ $REPLY =~ ^[Nn]$ ]]; then

      sign_eula

      break

    else

      echo "Please enter y or n"

    fi

  done

}

init_server () {

  echo "init"

  cd ${craft_server_dir}/${server_name}
  # screen -AmdS "$server_name" 
  java -jar -Xmx8192M ${craft_server_dir}/${server_name}/fabric-server-launch.jar --nogui --initSettings &
  wait

  ask_config_server

}

install_sever () {

  jar_count () { cd ${craft_server_dir}/${server_name}; ls -1 *.jar 2>/dev/null | wc -l; }

  if [ $(jar_count) == "0" ]; then 

    ohai "Installing ${server_name} server in ${craft_server_dir}/${server_name}"

    cd "$craft_server_dir"

    ${install_command} &
    wait

    init_server

  fi

}

create_server_dir () {

  ohai "Creating dir: ${craft_server_dir}/${server_name}"
  mkdir "${craft_server_dir}/${server_name}"

  install_sever

}

create_server () {
  
  if ! [ -d "${craft_server_dir}/${server_name}" ]; then 
    ohai "Creating ${server_name}"

    echo "
    Options: 
    Server name: ${server_name}
    Server dir: ${craft_server_dir}/${server_name}"

    install_command="${install_command} ${server_name}"
    if [ "${minecraft_version}" != false ] ; then
      install_command="${install_command} -mcversion ${minecraft_version}"
      echo "    Minecraft version: ${minecraft_version}"
    fi
    if [ "${loader}" != false ] ; then
      install_command="${install_command} -loader ${loader}"
      echo "    Fabric loader: ${loader}"
    fi
    if [ "${snapshot}" != false ] ; then
      install_command="${install_command} -snapshot"
      echo "   snapshot: ${snapshot}"
    fi

    echo ""

    create_server_dir
  else 
    warn "${server_name} already existis.
    
    To re-install first run:
    > craft delete -n ${server_name}

    The run:
    > craft create -n ${server_name} [ options ]
    "

  fi

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

  if [ "${server_name}" == false ] ; then
    missing_required_option "$command" "-n"
    exit 1
  fi

  create_server

}