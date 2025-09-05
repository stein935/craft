#!/usr/bin/env bash

command="server"
server_name=false
test=false

server_command() {

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

	echo

	[[ "${server_name}" == false ]] && missing_required_option "$command" "-n"

	find_server "${server_name}"

	get_properties

	if $test; then
		declare -A test_info=([command]="$command" [server_name]="$server_name" [test]="$test")
		test_form test_info
	fi

	view_server

}

view_server() {

	PID=$(netstat -vanp tcp | grep "${server_port}" | awk '{print $9}')
	if [ -n "$PID" ]; then
		execute "screen" "-r" "${server_name}"
		echo "$(date) : Server: \"${server_name}\" was viewed." >>"${CRAFT_SERVER_DIR}/${server_name}/logs/monitor/$(date '+%Y-%m').log"
	else
		warn "\"${server_name}\" is not running"
		$test && echo && runtime && echo
		exit 1
	fi
	$test && runtime && echo
	exit 0

}
