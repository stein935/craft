#!/usr/bin/env bash

: <<'END_COMMENT'
Tests:
	Valid commands:
		craft command -h
		craft command --help
		craft command -n ServerName -c "say Hello World"
		craft command -n ServerName -c "say Hello World" -t
	Invalid commands:
		craft command
		craft command -n ServerName
		craft command -c "say Hello World"
		craft command -n InvalidServer -c "say Hello World"
		craft command -n ServerName -c ""
		craft command -n ServerName -c "say Hello World" -x
END_COMMENT

command_command() {

	export command="command"
	export server_name=false
	server_command=false
	test=false

	[ -z "$1" ] && command_help "$command" 1

	while getopts ":n:c:th" opt; do
		case $opt in
		n) server_name="$OPTARG" ;;
		c) server_command="$OPTARG" ;;
		h) command_help "$command" 0 ;;
		t) test=true ;;
		:) missing_argument "$command" "$OPTARG" ;;
		*) invalid_option "$command" "$OPTARG" ;;
		esac
	done

	echo

	! [ -n "$server_name" ] && missing_required_option "$command" "-n" || ! [ "$server_command" ] && missing_required_option "$command" "-c"

	find_server "${server_name}"

	get_properties

	if $test; then
		# shellcheck disable=SC2034  # test_info used indirectly via nameref in test_form
		declare -A test_info=([command]="$command" [server_command]="$server_command" [server_name]="$server_name" [test]="$test")
		test_form test_info
	fi

	send_command

}

send_command() {

	if ! server_status &>/dev/null; then
		warn "$(form "bright_cyan" "italic" "\"${server_name}\"") is not running"
		$test && echo && runtime && echo
		exit 1
	fi

	cat "${CRAFT_SERVER_DIR}/${server_name}/logs/latest.log" >"${CRAFT_SERVER_DIR}/${server_name}/logs/latest.log.tmp"

	pipe="${CRAFT_SERVER_DIR}/${server_name}/command-pipe"
	send "Sending $(form "green" "italic" "\"${server_command}\"") to $(form "bright_cyan" "italic" "\"${server_name}\"") Minecraft server"
	echo "${server_command}" | tee "${pipe}" >/dev/null

	while true; do
		compare=$(comm -23 "${CRAFT_SERVER_DIR}/${server_name}/logs/latest.log" "${CRAFT_SERVER_DIR}/${server_name}/logs/latest.log.tmp")
		if [ -n "$compare" ]; then
			pattern='*INFO]: }'
			form "cyan" "normal" "${compare#"$pattern"}"
			echo
			echo "$(date) : Command: \"${server_command}\" sent to \"${server_name}\". Server log: ${compare}" >>"$CRAFT_SERVER_DIR/$server_name/logs/monitor/$(date '+%Y-%m').log"
			rm "${CRAFT_SERVER_DIR}/${server_name}/logs/latest.log.tmp"
			break
		fi
		sleep 1
	done

	$test && echo && runtime && echo
	exit 0
}
