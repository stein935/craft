#!/usr/bin/env bash
# PATH=/usr/local/bin:/usr/local/sbin:~/bin:/usr/bin:/bin:/usr/sbin:/sbin
PATH="/opt/homebrew/bin:$PATH"

command="monitor"
server_name=false
players=false
test=false

monitor_command() {

	[ -z "$1" ] && command_help "$command" 1

	while getopts ":n:hpt" opt; do
		case $opt in
		n) server_name="$OPTARG" ;;
		h) command_help "$command" 0 ;;
		p) players=true ;;
		t) test=true ;;
		:) missing_argument "$command" "$OPTARG" ;;
		*) invalid_option "$command" "$OPTARG" ;;
		esac
	done

	echo

	[[ "${server_name}" == false ]] && missing_required_option "$command" "-n"

	find_server "${server_name}"

	get_properties

	if $test; then
		declare -A test_info=([command]="$command" [server_name]="$server_name" [players]="$players" [test]="$test")
		test_form test_info
	fi

	monitor_server

}

monitor_server() {
	if server_status silent &>/dev/null; then
		exit 0
	fi
	execute "$0" "restart" "-mn" "${server_name}"
	pid
	echo "$(date) : Monitor: \"${server_name}\" was restarted automatically when a crash was detected. Port: ${server_port} PID: ${PID}" >>"${CRAFT_SERVER_DIR}/${server_name}/logs/monitor/$(date '+%Y-%m').log"
	if [ -n "$discord_webhook" ]; then
		discord_message "Auto Restart" "${server_name} was restarted automatically when a crash was detected" "12745742" "Server Monitor"
	fi
	execute "$0" "status" "-n" "${server_name}"
	exit 1
}
