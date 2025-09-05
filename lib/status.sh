#!/usr/bin/env bash

command="status"
server_name=false
test=false

status_command() {

	[ -z "$1" ] && command_help "$command" 1

	while getopts ":n:ht" opt; do
		case "$opt" in
		n) server_name=${OPTARG} ;;
		h) command_help "${command}" 0 ;;
		t) test=true ;;
		:) missing_argument "$command" "$OPTARG" ;;
		*) invalid_option "$command" "$OPTARG" ;;
		esac
	done

	echo

	[[ $(ls ${CRAFT_SERVER_DIR}) == "" ]] && warn "No servers found in ${CRAFT_SERVER_DIR}" && exit 1

	if $test; then
		declare -A test_info=([command]="$command" [server_name]="$server_name" [test]="$test")
		test_form test_info
	fi

	status=

	if [[ "${server_name}" == false ]]; then
		servers=$(ls "${CRAFT_SERVER_DIR}")
		while IFS=$'\t' read -r server; do
			server_name="${server}"
			get_properties
			server_status
			status=$?
		done <<<"${servers[@]}"
	else
		find_server "${server_name}"
		get_properties
		server_status
		status=$?
	fi

	$test && runtime && echo

	exit $status

}
