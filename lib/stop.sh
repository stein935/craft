#!/usr/bin/env bash

stop_command() {

	export command="stop"
	export server_name=false
	test=false

	while getopts ":n:ht" opt; do
		case $opt in
		n) server_name="$OPTARG" ;;
		h) command_help "$command" 0 ;;
		t) test=true ;;
		:) missing_argument "$command" "$OPTARG" ;;
		*) invalid_option "$command" "$OPTARG" ;;
		esac
	done

	if [[ "$server_name" == false ]]; then
		if [ -d "${CRAFT_SERVER_DIR}" ] && [ -z "$(ls "${CRAFT_SERVER_DIR}")" ]; then
			warn "No servers found in ${CRAFT_SERVER_DIR}"
			exit 1
		fi
		local servers
		servers=$(ls "${CRAFT_SERVER_DIR}")
		server_name=$(printf "%s\n" "${servers[@]##*/}" | use_fzf "Select a server") || exit 0
	fi

	echo

	find_server "${server_name}"

	get_properties

	if $test; then
		# shellcheck disable=SC2034  # test_info used indirectly via nameref in test_form
		declare -A test_info=([command]="$command" [server_name]="$server_name" [test]="$test")
		test_form test_info
	fi

	# OS detection for daemon/service management
	if [[ "$OSTYPE" == "darwin"* ]]; then
		stop_server
	elif command -v systemctl >/dev/null 2>&1; then
		# Linux systemd stop
		systemctl stop "craft.${server_name}.service"
		status=$?
		$test && runtime && echo
		exit $status
	else
		stop_server
	fi

}

stop_server() {

	trap 'clean_up' EXIT

	if ! server_on 0 >/dev/null; then
		warn "No server running on port: ${server_port:?server_port must be set by parent script}"
		exit 1
	fi

	fwhip "Stopping $(form "bright_cyan" "italic" "\"${server_name}\"") Minecraft server"

	pipe="${CRAFT_SERVER_DIR}/${server_name}/command-pipe"
	send "Sending save-all and stop commands to the server ..."
	echo "save-all" | tee "$pipe" >/dev/null
	echo "stop" | tee "$pipe" >/dev/null

	local -i status

	if server_off >/dev/null; then
		fwhip "$(form "bright_cyan" "italic" "\"${server_name}\"") Minecraft server stopped"
		echo "$(date) : Stop: \"${server_name}\" stopped" >>"${CRAFT_SERVER_DIR}/${server_name}/logs/monitor/$(date '+%Y-%m').log"
		status=0
	else
		warn "Unable to stop the server running on PID: $(form bright_red normal "$PID")"
		status=1
	fi

	$test && runtime && echo

	exit $status

}

clean_up() {
	sleep 2
	if [[ "$OSTYPE" == "darwin"* ]]; then
		# macOS - use launchctl/plutil
		launchctl bootout system/"craft.${server_name// /}.daemon" >/dev/null 2>&1
		rm -f "/Library/LaunchDaemons/craft.${server_name// /}.daemon.plist" >/dev/null 2>&1
	elif command -v systemctl >/dev/null 2>&1; then
		# Linux with systemd
		systemctl stop "craft.${server_name}.service" >/dev/null 2>&1
		systemctl disable "craft.${server_name}.service" >/dev/null 2>&1
		rm -f "/etc/systemd/system/craft.${server_name}.service" >/dev/null 2>&1
	fi
	rm -f "$pipe" >/dev/null 2>&1
}
