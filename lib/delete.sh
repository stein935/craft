#!/usr/bin/env bash

delete_command() {

	export command="delete"
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

	echo

	[[ "$server_name" != false ]] || missing_required_option "$command" "-n"

	find_server "${server_name}"

	get_properties

	if $test; then
		# shellcheck disable=SC2034  # test_info used indirectly via nameref in test_form
		declare -A test_info=([command]="$command" [server_name]="$server_name" [test]="$test")
		test_form test_info
	fi

	delete_server

}

delete_server() {

	server_on 0 >/dev/null && rm_line && execute "$0" "stop" "-n" "${server_name}"

	if [ -d "${CRAFT_SERVER_DIR}/${server_name}" ]; then
		read -p "$(warn "Are you sure you want to permanently delete \"${server_name}?\" (y/n) : ")" -n 1 -r
		echo && echo
		if [[ $REPLY =~ ^[Yy]$ ]]; then
			fwhip "Deleting dir: ${CRAFT_SERVER_DIR}/${server_name// /\ }"
			execute "rm" "-r" "${CRAFT_SERVER_DIR}/${server_name}"
			[ -f "/Library/LaunchDaemons/craft.${server_name// /}.daemon.plist" ] && fwhip "Checking for sudo ..." && sudo ls &>/dev/null && sudo rm /Library/LaunchDaemons/craft."${server_name// /}".daemon.plist
		else
			fwhip "Cancelled"
		fi
	else
		warn "\"${server_name}\" does not exist in ${CRAFT_SERVER_DIR}"
		exit 1
	fi

	$test && runtime && echo
	exit 0

}
