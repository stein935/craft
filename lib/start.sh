#!/usr/bin/env bash

command="start"
server_name=false
server_init_mem="512M"
server_max_mem="8G"
test=false

start_command() {

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

	[[ ${server_name} == false ]] && missing_required_option "$command" "-n"

	echo

	find_server "${server_name}"

	get_properties

	if $test; then
		declare -A test_info=([command]="$command" [server_name]="$server_name" [server_init_mem]="$server_init_mem" [server_max_mem]="$server_max_mem" [test]="$test")
		test_form test_info
	fi

	start_server

}

start_server() {

	# Check if a server is already running on the port
	pid
	if [ $PID ]; then
		warn "A server is already running on port: $(form "green" "normal" "${server_port}") PID: $(form "green" "normal" "${PID}")"
		indent "$(form "red" "normal" "Run:")"
		indent "$(form "red" "normal" "craft stop -n \"${server_name}\" or $ craft restart -n \"${server_name}\"")" "6"
		echo
		$test && runtime && echo
		exit 1
	fi

	# Message that the server is starting
	fwhip "Starting \"${server_name}\" Minecraft server"

	if [ -f "${CRAFT_SERVER_DIR}/${server_name}/logo.txt" ]; then
		execute "cat" "${CRAFT_SERVER_DIR}/${server_name}/logo.txt"
		echo
	fi

	# Check for sudo access
	fwhip "Checking for sudo ..." && sudo ls &>/dev/null

	daemon_path="/Library/LaunchDaemons/craft.${server_name// /}.daemon.plist"
	craft_path=$(printf '%s\n' "${CRAFT_FILE}" | sed -e 's/[\/&]/\\&/g')
	log_path=$(printf '%s\n' "${CRAFT_SERVER_DIR}/${server_name}/logs/daemon.log" | sed -e 's/[\/&]/\\&/g')
	# Command to start the server
	mem=(-Xms${server_init_mem} -Xmx${server_max_mem})
	garbageCollection=(-XX:+UseG1GC -XX:MaxGCPauseMillis=130 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=28 -XX:G1HeapRegionSize=16M -XX:G1ReservePercent=20 -XX:G1MixedGCCountTarget=3 -XX:InitiatingHeapOccupancyPercent=10 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=0 -XX:SurvivorRatio=32 -XX:MaxTenuringThreshold=1 -XX:G1SATBBufferEnqueueingThresholdPercent=30 -XX:G1ConcMarkStepDurationMillis=5 -XX:G1ConcRSHotCardLimit=16 -XX:G1ConcRefinementServiceIntervalMillis=150)
	args=(-XX:+UnlockExperimentalVMOptions -XX:+UnlockDiagnosticVMOptions -XX:+AlwaysPreTouch -XX:+DisableExplicitGC -XX:+UseNUMA -XX:NmethodSweepActivity=1 -XX:ReservedCodeCacheSize=400M -XX:NonNMethodCodeHeapSize=12M -XX:ProfiledCodeHeapSize=194M -XX:NonProfiledCodeHeapSize=194M -XX:-DontCompileHugeMethods -XX:MaxNodeLimit=240000 -XX:NodeLimitFudgeFactor=8000 -XX:+UseVectorCmov -XX:+PerfDisableSharedMem -XX:+UseFastUnorderedTimeStamps -XX:+UseCriticalJavaThreadPriority -XX:ThreadPriorityPolicy=1 -XX:AllocatePrefetchStyle=3 -XX:+UseG1GC -XX:MaxGCPauseMillis=37 -XX:+PerfDisableSharedMem -XX:G1HeapRegionSize=16M -XX:G1NewSizePercent=23 -XX:G1ReservePercent=20 -XX:SurvivorRatio=32 -XX:G1MixedGCCountTarget=3 -XX:G1HeapWastePercent=20 -XX:InitiatingHeapOccupancyPercent=10 -XX:G1RSetUpdatingPauseTimePercent=0 -XX:MaxTenuringThreshold=1 -XX:G1SATBBufferEnqueueingThresholdPercent=30 -XX:G1ConcMarkStepDurationMillis=5.0 -XX:G1ConcRSHotCardLimit=16 -XX:G1ConcRefinementServiceIntervalMillis=150 -XX:GCTimeRatio=99 -XX:LargePageSizeInBytes=2m)
	command="java ${mem[@]} ${garbageCollection[@]} ${args[@]} -jar ${CRAFT_SERVER_DIR}/${server_name}/fabric-server-launch.jar --nogui"
	program() {
		wrapped_command=()
		read -r -a _cmd_parts <<<"$command"
		for _part in "${_cmd_parts[@]}"; do
			_esc=${_part//&/&amp;}
			_esc=${_esc//</&lt;}
			_esc=${_esc//>/&gt;}
			_esc=${_esc//\"/&quot;}
			_esc=${_esc//\'/&apos;}
			wrapped_command+=("<string>${_esc}</string>")
		done
		for i in "${!wrapped_command[@]}"; do
			if ((i == ${#wrapped_command[@]} - 1)); then
				printf '      %s' "${wrapped_command[i]}"
			else
				printf '      %s\\n' "${wrapped_command[i]}"
			fi
		done | sed -e 's/[&|]/\\&/g'
	}
	program_strings=$(program)

	if [ -f "/Library/LaunchDaemons/craft.${server_name// /}.daemon.plist" ]; then
		sudo rm -f /Library/LaunchDaemons/craft.${server_name// /}.daemon.plist
	fi

	sudo cp "${CRAFT_HOME_DIR}/config/craft.servername.daemon.plist" $daemon_path

	sudo sed -i '' "s|_server_name_|${server_name// /}|g" $daemon_path
	sudo sed -i '' "s|_user_|${USER}|g" $daemon_path
	sudo sed -i '' "s|_arguments_|${program_strings//&/\\&}|g" $daemon_path
	sudo sed -i '' "s|_working_dir_|${CRAFT_SERVER_DIR}/${server_name}|g" $daemon_path
	sudo sed -i '' "s|_log_path_|${log_path}|g" $daemon_path

	if [ ! -f "${CRAFT_SERVER_DIR}/${server_name}/logs/daemon.log" ]; then execute "touch" "${CRAFT_SERVER_DIR}/${server_name}/logs/daemon.log"; fi

	! sudo launchctl list | grep "craft.${server_name// /}.daemon" &>/dev/null && sudo launchctl load $daemon_path

	sleep 3

	while true; do
		while read -r line; do
			if [[ "$line" == *"Done"* ]]; then
				break 2
			fi
		done <"${CRAFT_SERVER_DIR}/${server_name}/logs/latest.log"
		sleep 1
	done

	# Do this if the server is running
	echo
	server_status && echo "$(date) : Start: \"${server_name}\" running on port: ${server_port} PID: ${PID}" >>"${CRAFT_SERVER_DIR}/${server_name}/logs/monitor/$(date '+%Y-%m').log"

	$test && runtime && echo

	exit 0
}
