#!/usr/bin/env bash

command="stop"
server_name=false
force=false
monitor=false
test=false

stop_command() {

	[ -z "$1" ] && command_help "$command" 1

	while getopts ":n:fmht" opt; do
		case $opt in
		n) server_name="$OPTARG" ;;
		m) monitor=true ;;
		f) force=true ;;
		h) command_help "$command" 0 ;;
		t) test=true ;;
		:) missing_argument "$command" "$OPTARG" ;;
		*) invalid_option "$command" "$OPTARG" ;;
		esac
	done

	[[ "${server_name}" == false ]] && missing_required_option "$command" "-n"

	echo

	find_server "${server_name}"

	get_properties

	if $test; then
		declare -A test_info=([command]="$command" [server_name]="$server_name" [force]="$force" [monitor]="$monitor" [test]="$test")
		test_form test_info
	fi

	stop_server

}

stop_server() {

	pid

	if ! [ $PID ]; then
		warn "No server running on port: ${server_port}"
		! $force && indent "To force stop run:" && indent "craft stop -fn \"${server_name}\"" "6" && echo && exit 1 || warn "Force stopping all related processes ... just in case"
	else
		fwhip "Stopping \"${server_name}\" Minecraft server"
	fi

	if ! $monitor; then
		fwhip "Checking for sudo ..." && sudo ls &>/dev/null
		sudo launchctl list | grep "craft.${server_name// /}.daemon" &>/dev/null && [ -f "/Library/LaunchDaemons/craft.${server_name// /}.daemon.plist" ] && sudo launchctl unload /Library/LaunchDaemons/craft.${server_name// /}.daemon.plist
		[ -f "/Library/LaunchDaemons/craft.${server_name// /}.daemon.plist" ] && sudo rm -f /Library/LaunchDaemons/craft.${server_name// /}.daemon.plist
	fi

	cd "${CRAFT_SERVER_DIR}/${server_name}"
	pipe=command-pipe
	exec <>$pipe

	if [ $PID ]; then
		if [ -p $pipe ]; then
			echo save-all >>$pipe
			echo stop >>$pipe
			i=0
			printf '%s' "$(tty_escape "2;36")"
			tail -f logs/latest.log &
			tailpid=$!
			until [ $i -gt 15 ]; do
				while read -r line; do
					if [[ "$line" == *"All dimensions are saved"* ]]; then
						kill $tailpid
						break 2
					fi
				done <"${CRAFT_SERVER_DIR}/${server_name}/logs/latest.log"
				((i = i + 1))
				sleep 1
			done
			echo "$(tty_escape 0)"
			if [ $i -gt 15 ]; then
				warn "Unable to run save-all and stop. Some game data may have been lost"
				kill -9 $PID
			fi
		else
			warn "Unable to run save-all and stop. Some game data may have been lost"
			kill -9 $PID
		fi
	fi

	fwhip "\"${server_name}\" Minecraft server stopped"
	echo "$(date) : Stop: \"${server_name}\" stopped" >>"${CRAFT_SERVER_DIR}/${server_name}/logs/monitor/$(date '+%Y-%m').log"
	$test && runtime && echo
	exit 0

}
