#!/usr/bin/env bash

stop_command() {

	export command="stop"
	export server_name=false
	test=false

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
		# shellcheck disable=SC2034  # test_info used indirectly via nameref in test_form
		declare -A test_info=([command]="$command" [server_name]="$server_name" [test]="$test")
		test_form test_info
	fi

	stop_server

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
		# kill -9 "${PID:?PID must be set by parent script}"
	fi

	$test && runtime && echo

	exit $status

}

clean_up() {
	sleep 2
	launchctl bootout system/"craft.${server_name// /}.daemon" >/dev/null 2>&1
	rm -f "/Library/LaunchDaemons/craft.${server_name// /}.daemon.plist" >/dev/null 2>&1
	rm -f "$pipe" >/dev/null 2>&1
}
