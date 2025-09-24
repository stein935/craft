#!/usr/bin/env bash

start_command() {

	export command="start"
	export server_name=false
	server_init_mem="512M"
	server_max_mem="8G"
	daemon=false
	test=false

	[ -z "$1" ] && command_help "$command" 1

	while getopts ":n:dht" opt; do
		case $opt in
		n) server_name="$OPTARG" ;;
		d) daemon=true ;;
		h) command_help "$command" 0 ;;
		t) test=true ;;
		:) missing_argument "$command" "$OPTARG" ;;
		*) invalid_option "$command" "$OPTARG" ;;
		esac
	done

	! [ -n "$server_name" ] && missing_required_option "$command" "-n"

	echo

	find_server "${server_name}"

	get_properties

	if $test; then
		# shellcheck disable=SC2034  # test_info used indirectly via nameref in test_form
		declare -A test_info=([command]="$command" [server_name]="$server_name" [server_init_mem]="$server_init_mem" [server_max_mem]="$server_max_mem" [test]="$test")
		test_form test_info
	fi

	check_java "$(ls "${CRAFT_SERVER_DIR}/${server_name}/versions")"

	$daemon && start_daemon

	start_server

}

start_daemon() {
	mem=("-Xms${server_init_mem}" "-Xmx${server_max_mem}")
	args=("-XX:+UnlockExperimentalVMOptions" "-XX:+UnlockDiagnosticVMOptions" "-XX:MaxGCPauseMillis=130" "-XX:G1MixedGCLiveThresholdPercent=90" "-XX:+AlwaysPreTouch" "-XX:+DisableExplicitGC" "-XX:+UseNUMA" "-XX:NmethodSweepActivity=1" "-XX:ReservedCodeCacheSize=400M" "-XX:NonNMethodCodeHeapSize=12M" "-XX:ProfiledCodeHeapSize=194M" "-XX:NonProfiledCodeHeapSize=194M" "-XX:-DontCompileHugeMethods" "-XX:MaxNodeLimit=240000" "-XX:NodeLimitFudgeFactor=8000" "-XX:+UseVectorCmov" "-XX:+PerfDisableSharedMem" "-XX:+UseFastUnorderedTimeStamps" "-XX:+UseCriticalJavaThreadPriority" "-XX:ThreadPriorityPolicy=1" "-XX:AllocatePrefetchStyle=3" "-XX:+UseG1GC" "-XX:+PerfDisableSharedMem" "-XX:G1HeapRegionSize=16M" "-XX:G1NewSizePercent=23" "-XX:G1ReservePercent=20" "-XX:SurvivorRatio=32" "-XX:G1MixedGCCountTarget=3" "-XX:G1HeapWastePercent=20" "-XX:InitiatingHeapOccupancyPercent=10" "-XX:G1RSetUpdatingPauseTimePercent=0" "-XX:MaxTenuringThreshold=1" "-XX:G1SATBBufferEnqueueingThresholdPercent=30" "-XX:G1ConcMarkStepDurationMillis=5" "-XX:G1ConcRSHotCardLimit=16" "-XX:G1ConcRefinementServiceIntervalMillis=150" "-XX:GCTimeRatio=99" "-XX:LargePageSizeInBytes=2m")
	# Build the Java command as an array to preserve argument boundaries
	java_cmd=("$(command -v java)" "${mem[@]}" "${args[@]}" -jar "${CRAFT_SERVER_DIR}/${server_name}/fabric-server-launch.jar" --nogui)

	# Redirect stdin from the named pipe instead of passing "<" as an argument
	"${java_cmd[@]}" <>"${CRAFT_SERVER_DIR}/${server_name}/command-pipe"
	exit 0
}

start_server() {

	# Check if a server is already running on the port
	if server_status false 1 >/dev/null; then
		warn "A server is already running on port: $(form "green" "normal" "${server_port:?server_port must be set by parent script}") PID: $(form "green" "normal" "${PID:?PID must be set by parent script}")"
		indent "$(form "bright_red" "underline" "Run:")"
		indent "craft stop -n \"${server_name}\"" "6"
		echo
		$test && runtime && echo
		exit 1
	fi

	# Message that the server is starting
	fwhip "Starting $(form "bright_cyan" "italic" "\"${server_name}\"") Minecraft server"

	daemon_path="/Library/LaunchDaemons/craft.${server_name// /}.daemon.plist"
	log_path=$(printf '%s\n' "${CRAFT_SERVER_DIR}/${server_name}/logs/daemon.log" | sed -e 's/[\/&]/\\&/g')

	# Make pipe if it doesn't exist
	if [ ! -p "${CRAFT_SERVER_DIR}/${server_name}/command-pipe" ]; then
		execute "mkfifo" "${CRAFT_SERVER_DIR}/${server_name}/command-pipe"
	fi

	# Command to start the server
	daemon_command="$(which bash) $(which craft) start -n ${server_name} -d"
	program() {
		wrapped_command=()
		read -r -a _cmd_parts <<<"$daemon_command"
		for _part in "${_cmd_parts[@]}"; do
			_esc=${_part//&/&amp;}
			_esc=${_esc//</\&lt;}
			_esc=${_esc//>/\&gt;}
			_esc=${_esc//\"/\&quot;}
			_esc=${_esc//\'/\&apos;}
			wrapped_command+=("      <string>${_esc}</string>")
		done
		printf "%s\n" "${wrapped_command[@]}"
	}
	program_strings=$(program)

	# Unload and remove existing daemon
	launchctl bootout system/"craft.${server_name// /}.daemon" 2>/dev/null
	rm -f /Library/LaunchDaemons/craft."${server_name// /}".daemon.plist 2>/dev/null

	cp "${CRAFT_HOME_DIR}/config/craft.servername.daemon.plist" "$daemon_path"

	sed -i '' "s|_server_name_|${server_name// /}|g" "$daemon_path"
	sed -i '' "s|_user_|${USER}|g" "$daemon_path"
	sed -i '' "s|_working_dir_|${CRAFT_SERVER_DIR}/${server_name}|g" "$daemon_path"
	sed -i '' "s|_log_path_|${log_path}|g" "$daemon_path"

	awk '
	  /_arguments_/ {
	    while ((getline line < ARGV[2]) > 0) print line
	    ARGV[2] = ""
	    next
	  }
	  { print }
	' "$daemon_path" <(printf "%s\n" "$program_strings") >"${daemon_path}.tmp" && mv "${daemon_path}.tmp" "$daemon_path"

	rm -f "${CRAFT_SERVER_DIR}/${server_name}/logs/daemon.log" 2>/dev/null

	touch "${CRAFT_SERVER_DIR}/${server_name}/logs/daemon.log"

	# Load daemon
	launchctl bootstrap system "$daemon_path" 2>/dev/null

	# Do this if the server is running
	if server_status; then

		echo "$(date) : Start: \"${server_name}\" running on port: ${server_port} PID: ${PID:?PID must be set by parent script}" >>"${CRAFT_SERVER_DIR}/${server_name}/logs/monitor/$(date '+%Y-%m').log"

		if [ -f "${CRAFT_SERVER_DIR}/${server_name}/logo.txt" ]; then
			form "cyan" "dim" "$(execute "cat" "${CRAFT_SERVER_DIR}/${server_name}/logo.txt")"
			echo && echo
		fi

	fi

	$test && runtime && echo

	exit 0
}
