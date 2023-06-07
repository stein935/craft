#!/usr/bin/env bash

command="create"
server_name=false
minecraft_version=false
loader=false
snapshot=false
install_command="java -jar ${CRAFT_HOME_DIR}/config/fabric-installer.jar server -downloadMinecraft -dir"
test=false

sign_eula () {

   while true; do

    ohai "Agree to Minecraft eula for ${server_name}?"
    read -p "(y/n) : " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
    
      ohai "Sigining ${CRAFT_SERVER_DIR}/${server_name}/eula.txt"
      sed -i '' -e '$ d' "${CRAFT_SERVER_DIR}/${server_name}/eula.txt"
      echo "eula=true" >> ${CRAFT_SERVER_DIR}/${server_name}/eula.txt

      break

    elif [[ $REPLY =~ ^[Nn]$ ]]; then

      warn "You will need to accept eula by editing ${CRAFT_SERVER_DIR}/${server_name}/eula.txt 
      before you can start the server" 

      break

    else

      echo "Please enter y or n"

    fi

  done

  ohai "${server_name} has been created!"
  echo
  echo "  Server location ${CRAFT_SERVER_DIR}/${server_name}"
  echo "  To start the server - Run:
      craft start -n ${server_name}"
  echo
  mkdir $CRAFT_SERVER_DIR/$server_name/logs/monitor
  echo "$(date) : Create: ${server_name} created!" >> $CRAFT_SERVER_DIR/$server_name/logs/monitor/$(date '+%Y-%m').log

  exit 0

}

ask_config_server () {

  # Add initial fabric-server-properties
  echo -e "#Fabric launcher properties\n$(cat ${CRAFT_SERVER_DIR}/${server_name}/fabric-server-launcher.properties)" > ${CRAFT_SERVER_DIR}/${server_name}/fabric-server-launcher.properties
  echo "server_init_mem=512M" >> "${CRAFT_SERVER_DIR}/${server_name}/fabric-server-launcher.properties"
  echo "server_max_mem=8G" >> "${CRAFT_SERVER_DIR}/${server_name}/fabric-server-launcher.properties"
  echo "discord_webhook=" >> "${CRAFT_SERVER_DIR}/${server_name}/fabric-server-launcher.properties"

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

  cd ${CRAFT_SERVER_DIR}/${server_name}
  # screen -AmdS "$server_name" 
  java -jar -Xmx8192M ${CRAFT_SERVER_DIR}/${server_name}/fabric-server-launch.jar --nogui --initSettings &
  wait

  ask_config_server

}

install_sever () {

  jar_count () { cd ${CRAFT_SERVER_DIR}/${server_name}; ls -1 *.jar 2>/dev/null | wc -l; }

  if [ $(jar_count) == "0" ]; then 

    ohai "Installing ${server_name} server in ${CRAFT_SERVER_DIR}/${server_name}"

    cd "$CRAFT_SERVER_DIR"

    ${install_command} &
    wait

    init_server

  fi

}

create_server_dir () {

  ohai "Creating dir: ${CRAFT_SERVER_DIR}/${server_name}"
  mkdir "${CRAFT_SERVER_DIR}/${server_name}"

  install_sever

}

create_server () {
  
  if ! [ -d "${CRAFT_SERVER_DIR}/${server_name}" ]; then 
    ohai "Creating ${server_name}"

    echo "
    Options: 
    Server name: ${server_name}
    Server dir: ${CRAFT_SERVER_DIR}/${server_name}"

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
      craft delete -n ${server_name}

    To run:
      craft create -n ${server_name} [ options ]
    "

  fi

}

create_command () {

  [ ! -n "$1" ] && command_help "$command" 1

	while getopts ":n:v:l:i:m:sht" opt; do
    case $opt in 
      n ) server_name="$OPTARG" ;;
      v ) minecraft_version="$OPTARG" ;;
      l ) loader="$OPTARG" ;;
      s ) snapshot=true ;;
      h ) command_help "$command" 0 ;;
      t ) test=true ;;
      : ) missing_argument "$command" "$OPTARG" ;;
      * ) invalid_option "$command" "$OPTARG" ;;
    esac
  done

  if [ "${server_name}" == false ] ; then
    missing_required_option "$command" "-n"
  fi

  if [[ "$test" == true ]]; then
    echo "command                 : $command        "
    echo "server_name             : $server_name    "
    echo "minecraft_version       : $minecraft_version"
    echo "loader                  : $loader         "
    echo "snapshot                : $snapshot       "
    echo "install_command         : $install_command"
    echo "test                    : $test           "
  fi

  create_server

}