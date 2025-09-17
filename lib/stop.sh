#!/usr/bin/env bash

command="stop"
server_name=false
test=false

stop_command() {

	[ -z "$1" ] && command_help "$command" 1

	while getopts ":n:ht" opt; do
		case $opt in
		n) server_name="$OPTARG" ;;
		h) command_help "$command" 0 ;;
		t) test=true ;;
		:) missing_argument "$command" "$OPTARG" ;;
		*) invalid_option "$command" "$OPTARG" ;;
		esac
	done

	! [ -n "$server_name" ] && missing_required_option "$command" "-n"

	echo

	find_server "${server_name}"

	get_properties

	if $test; then
		declare -A test_info=([command]="$command" [server_name]="$server_name" [test]="$test")
		test_form test_info
	fi

	stop_server

}

stop_server() {

	if ! pid true 1 >/dev/null; then
		warn "No server running on port: ${server_port}"
		exit 1
	fi

	fwhip "Stopping $(form "bright_cyan" "italic" "\"${server_name}\"") Minecraft server"

	pipe="${CRAFT_SERVER_DIR}/${server_name}/command-pipe"
	send "Sending save-all and stop commands to the server ..."
	echo "save-all" | tee "${CRAFT_SERVER_DIR}/${server_name}/command-pipe" >/dev/null
	echo "stop" | tee "${CRAFT_SERVER_DIR}/${server_name}/command-pipe" >/dev/null

	launchctl bootout system/"craft.${server_name// /}.daemon" 2>/dev/null
	rm -f /Library/LaunchDaemons/craft.${server_name// /}.daemon.plist 2>/dev/null

	if pid false >/dev/null; then
		fwhip "$(form "bright_cyan" "italic" "\"${server_name}\"") Minecraft server stopped"
		ring_bell
		echo "$(date) : Stop: \"${server_name}\" stopped" >>"${CRAFT_SERVER_DIR}/${server_name}/logs/monitor/$(date '+%Y-%m').log"
	else
		warn "Unable to run save-all and stop. Some game data may have been lost"
		kill -9 $(pid)
	fi

	$test && runtime && echo
	exit 0

}
