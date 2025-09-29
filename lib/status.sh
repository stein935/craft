#!/usr/bin/env bash

status_command() {

	export command="status"
	export server_name=false
	test=false

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

	if [ -d "${CRAFT_SERVER_DIR}" ] && [ -z "$(ls "${CRAFT_SERVER_DIR}")" ]; then
		warn "No servers found in ${CRAFT_SERVER_DIR}"
		exit 1
	fi

	if $test; then
		# shellcheck disable=SC2034  # test_info used indirectly via nameref in test_form
		declare -A test_info=([command]="$command" [server_name]="$server_name" [test]="$test")
		test_form test_info
	fi

	if [[ "${server_name}" == false ]]; then
		servers=$(ls "${CRAFT_SERVER_DIR}")
		while IFS=$'\t' read -r server; do
			server_name="${server}"
			get_properties
			server_on 0
		done <<<"${servers[@]}"
		status=0
	else
		find_server "${server_name}"
		get_properties
		server_on 0
		status=$?
	fi

	$test && runtime && echo

	exit "$status"

}
