#!/usr/bin/env bash

command="restart"
server_name=false
test=false
monitor=

restart_command() {

	[ -z "$1" ] && command_help "$command" 1

	while getopts ":n:mht" opt; do
		case $opt in
		n) server_name="$OPTARG" ;;
		m) monitor="m" ;;
		h) command_help "$command" 0 ;;
		t) test=true ;;
		:) missing_argument "$command" "$OPTARG" ;;
		*) invalid_option "$command" "$OPTARG" ;;
		esac
	done

	echo

	[[ "${server_name}" == false ]] && missing_required_option "$command" "-n"

	find_server "${server_name}"

	if $test; then
		declare -A test_info=([command]="$command" [server_name]="$server_name" [monitor]="$monitor" [test]="$test")
		test_form test_info
	fi

	restart_server

}

restart_server() {

	echo "$(date) : Restart: \"${server_name}\" was restarted." >>"${CRAFT_SERVER_DIR}/${server_name}/logs/monitor/$(date '+%Y-%m').log"
	execute "$0" "stop" "-${monitor}fn" "${server_name}"
	execute "$0" "start" "-dn" "${server_name}"
	$test && runtime && echo
	exit 0

}
