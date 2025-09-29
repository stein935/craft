#!/usr/bin/env bash

restart_command() {

	export command="restart"
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

	echo

	! [ -n "$server_name" ] && missing_required_option "$command" "-n"

	find_server "${server_name}"

	get_properties

	if $test; then
		# shellcheck disable=SC2034  # test_info used indirectly via nameref in test_form
		declare -A test_info=([command]="$command" [server_name]="$server_name" [test]="$test")
		test_form test_info
	fi

	restart_server

}

restart_server() {

	if server_on 0 >/dev/null; then
		echo "$(date) : Restart: \"${server_name}\" was restarted." >>"${CRAFT_SERVER_DIR}/${server_name}/logs/monitor/$(date '+%Y-%m').log"
		execute "$0" "stop" "-n" "${server_name}"
	else
		warn "No server running on port: ${server_port:?server_port must be set by parent script}"
	fi
	execute "$0" "start" "-n" "${server_name}"
	status=$?
	$test && runtime && echo
	exit $status

}
