#!/usr/bin/env bash

command="command"
server_command=false
server_name=false
monitor=false
test=false

command_command() {

	[ -z "$1" ] && command_help "$command" 1

	while getopts ":n:c:tmh" opt; do
		case $opt in
		n) server_name="$OPTARG" ;;
		c) server_command="$OPTARG" ;;
		m) monitor=true ;;
		h) command_help "$command" 0 ;;
		t) test=true ;;
		:) missing_argument "$command" "$OPTARG" ;;
		*) invalid_option "$command" "$OPTARG" ;;
		esac
	done

	echo

	[[ "$server_name" == false ]] && [[ "$server_command" == false ]] && missing_required_option "$command" "-n and -c"

	find_server "${server_name}"

	get_properties

	if $test; then
		declare -A test_info=([command]="$command" [server_command]="$server_command" [server_name]="$server_name" [monitor]="$monitor" [test]="$test")
		test_form test_info
	fi

	command_server

}

command_server() {
	if ! server_status silent &>/dev/null; then
		warn "\"${server_name}\" is not running"
		$test && echo && runtime && echo
		exit 1
	fi

	! $monitor && fwhip "Sending $(form "green" "italic" "\"${server_command}\"") to $(form "green" "italic" "\"${server_name}\"") Minecraft server"
	execute "cat" "${CRAFT_SERVER_DIR}/${server_name}/logs/latest.log" >"${CRAFT_SERVER_DIR}/${server_name}/logs/latest.log.tmp"

	cd "${CRAFT_SERVER_DIR}/${server_name}"
	pipe=command-pipe
	exec <>$pipe

	printf '%s\r' "${server_command}" >>$pipe

	while [ 1 ]; do
		compare=$(comm -23 "${CRAFT_SERVER_DIR}/${server_name}/logs/latest.log" "${CRAFT_SERVER_DIR}/${server_name}/logs/latest.log.tmp")
		if [ -n "$compare" ]; then
			form "cyan" "normal" "$(indent "$compare")"
			echo
			! $monitor && echo "$(date) : Command: \"${server_command}\" sent to \"${server_name}\". Server log: ${compare}" >>"$CRAFT_SERVER_DIR/$server_name/logs/monitor/$(date '+%Y-%m').log"
			execute "rm" "${CRAFT_SERVER_DIR}/${server_name}/logs/latest.log.tmp"
			break
		fi
		sleep 1
	done

	$test && echo && runtime && echo
	exit 0
}
