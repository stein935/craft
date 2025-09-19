#!/usr/bin/env bash

: <<'END_COMMENT'
Tests:
	Valid commands:
		craft delete -h
		craft delete --help
		craft delete -n ServerName
		craft delete -n ServerName -t
	Invalid commands:
		craft delete
		craft delete -x
		craft delete -n
		craft delete -t
		craft delete -n ServerName -x
		craft delete -n InvalidServer
		craft delete -n InvalidServer -t
END_COMMENT

command="delete"
server_name=false
test=false

delete_command() {

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

	if $test; then
		# shellcheck disable=SC2034  # test_info used indirectly via nameref in test_form
		declare -A test_info=([command]="$command" [server_name]="$server_name" [test]="$test")
		test_form test_info
	fi

	delete_server

}

delete_server() {

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
