#!/usr/bin/env bash

command="create"
server_name=false
minecraft_version=false
loader=false
snapshot=false
install_command=("java" "-jar" "${CRAFT_HOME_DIR}/config/fabric-installer.jar" "server" "-downloadMinecraft" "-dir")
get_init_command() { init_command=("java" "-jar" "-Xmx8192M" "${CRAFT_SERVER_DIR}/${server_name}/fabric-server-launch.jar" "--nogui" "--initSettings"); }
test=false

create_command() {

  [ -z "$1" ] && command_help "$command" 1

  while getopts ":n:v:l:i:m:sht" opt; do
    case $opt in
    n) server_name="$OPTARG" ;;
    v) minecraft_version="$OPTARG" ;;
    l) loader="$OPTARG" ;;
    s) snapshot=true ;;
    h) command_help "$command" 0 ;;
    t) test=true ;;
    :) missing_argument "$command" "$OPTARG" ;;
    *) invalid_option "$command" "$OPTARG" ;;
    esac
  done

  [[ "${server_name}" == false ]] && missing_required_option "$command" "-n"

  if $test; then
    echo "${tty_yellow}"
    indent "command                 : $command        "
    indent "server_name             : $server_name    "
    indent "minecraft_version       : $minecraft_version"
    indent "loader                  : $loader         "
    indent "snapshot                : $snapshot       "
    indent "install_command         : $install_command"
    indent "test                    : $test           "
    echo "${tty_reset}"
  fi

  create_server

}

create_server() {

  if ! [ -d "${CRAFT_SERVER_DIR}/${server_name}" ]; then
    fwhip "Creating \"${server_name}\""
    echo
    indent "${tty_underline}Options:${tty_reset}"
    indent "Server name: \"${server_name}\""
    indent "Server dir: $(printf '%q' "${CRAFT_SERVER_DIR}/${server_name}")"

    install_command+=("${server_name}")
    if [ "${minecraft_version}" != false ]; then
      install_command+=("-mcversion" "${minecraft_version}")
      indent "Minecraft version: ${minecraft_version}"
    fi
    if [ "${loader}" != false ]; then
      install_command+=("-loader" "${loader}")
      indent "Fabric loader: ${loader}"
    fi
    if [ "${snapshot}" != false ]; then
      install_command+=("-snapshot")
      indent "snapshot: ${snapshot}"
    fi

    echo

    create_server_dir
  else
    warn "\"${server_name}\" already existis."
    echo
    indent "To re-install first run:"
    indent "craft delete -n \"${server_name}\"" "6"
    echo
    indent "To run:"
    indent "craft create -n 
    \"${server_name}\" [ options ]" "6"
    $test && echo && runtime
    echo
    exit 1
  fi

}

create_server_dir() {

  fwhip "Creating dir: $(printf '%q' "${CRAFT_SERVER_DIR}/${server_name}")"
  mkdir "${CRAFT_SERVER_DIR}/${server_name}"

  install_sever

}

install_sever() {

  jar_count() { find "${CRAFT_SERVER_DIR}/${server_name}" | grep -c '\.jar$'; }

  execute "cd" "${CRAFT_SERVER_DIR}"

  if [[ $(jar_count) == "0" ]]; then
    fwhip "Installing \"${server_name}\" server in $(printf '%q' "${CRAFT_SERVER_DIR}/${server_name}")"
    echo "${tty_cyan}"
    execute "${install_command[@]}"
    echo "${tty_reset}"
    wait

    init_server
  else
    warn "There are already .jar files in $(printf '%q' "${CRAFT_SERVER_DIR}/${server_name}")"
  fi

}

init_server() {

  get_init_command
  execute "cd" "${CRAFT_SERVER_DIR}/${server_name}"
  echo "${tty_cyan}"
  execute "${init_command[@]}"
  echo "${tty_reset}"
  wait

  create_daemon

}

create_daemon() {

  daemon_path="/Library/LaunchDaemons/craft.${server_name// /}.daemon.plist"
  log_path=$(printf '%s\n' "${CRAFT_SERVER_DIR}/${server_name}/logs/daemon.log" | sed -e 's/[\/&]/\\&/g')

  sudo cp "${CRAFT_HOME_DIR}/config/craft.servername.daemon.plist" /Library/LaunchDaemons/craft.${server_name// /}.daemon.plist

  sudo sed -i '' "s/_servername_/${server_name// /}/g" $daemon_path
  sudo sed -i '' "s/_server_name_/${server_name// /\ }/g" $daemon_path
  sudo sed -i '' "s/_log_path_/${log_path}/g" $daemon_path
  sudo sed -i '' "s/_user_/${USER}/g" $daemon_path

  execute "touch" "${CRAFT_SERVER_DIR}/${server_name}/logs/daemon.log"

  ask_config_server

}

ask_config_server() {

  # Add initial fabric-server-properties
  echo -e "#Fabric launcher properties\n$(execute "cat" "${CRAFT_SERVER_DIR}/${server_name}/fabric-server-launcher.properties")" >"${CRAFT_SERVER_DIR}/${server_name}/fabric-server-launcher.properties"
  echo "server_init_mem=512M" >>"${CRAFT_SERVER_DIR}/${server_name}/fabric-server-launcher.properties"
  echo "server_max_mem=2G" >>"${CRAFT_SERVER_DIR}/${server_name}/fabric-server-launcher.properties"
  echo "discord_webhook=" >>"${CRAFT_SERVER_DIR}/${server_name}/fabric-server-launcher.properties"

  # Ask about custom config
  while true; do
    fwhip "Do you want to configure \"${server_name}\"?"
    read -p "(y/n) : " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      $0 config -n "${server_name}"
      sign_eula
      break
    elif [[ $REPLY =~ ^[Nn]$ ]]; then
      sign_eula
      break
    else
      warn "Please enter y or n"
    fi
  done

}

sign_eula() {

  while true; do

    fwhip "Agree to Minecraft eula for \"${server_name}\"?"
    read -p "(y/n) : " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      fwhip "Sigining $(printf '%q' "${CRAFT_SERVER_DIR}/${server_name}")/eula.txt"
      sed -i '' -e '$ d' "${CRAFT_SERVER_DIR}/${server_name}/eula.txt"
      echo "eula=true" >>"${CRAFT_SERVER_DIR}/${server_name}/eula.txt"
      break
    elif [[ $REPLY =~ ^[Nn]$ ]]; then
      warn "You will need to accept eula by editing $(printf '%q' "${CRAFT_SERVER_DIR}/${server_name}")/eula.txt before you can start the server"
      break
    else
      warn "Please enter y or n"
    fi

  done

  fwhip "\"${server_name}\" has been created!"
  echo
  indent "${tty_underline}Server location${tty_reset}: $(printf '%q' "${CRAFT_SERVER_DIR}/${server_name}")"
  echo
  indent "${tty_underline}Next steps${tty_reset}:"
  indent "To start the server - Run:"
  indent "craft start -n \"${server_name}\"" "6"
  echo
  mkdir "${CRAFT_SERVER_DIR}/${server_name}/logs/monitor"
  echo "$(date) : Create: \"${server_name}\" created!" >>"${CRAFT_SERVER_DIR}/${server_name}/logs/monitor/$(date '+%Y-%m').log"
  $test && echo && runtime
  echo
  exit 0

}
