#!/usr/bin/env bash

# Bits
ring_bell() { [ -t 1 ] && printf "\a"; }

# string formatters
[ -t 1 ] && tty_escape() { printf "\033[%sm" "$1"; } || tty_escape() { :; }

# ANSI color codes
declare -A color=(
	[black]=0
	[red]=1
	[green]=2
	[yellow]=3
	[blue]=4
	[magenta]=5
	[cyan]=6
	[white]=7
	[normal]=9
)

# ANSI text format codes
declare -A style=(
	[normal]=0
	[bold]=1
	[dim]=2
	[italic]=3
	[underline]=4
	[blink]=5
	[reverse]=7
	[hidden]=8
)

form_get() {
	local -n obj=$1
	echo "${obj[$2]}"
}

form() {
	if [[ $1 == bright_* ]]; then
		local -i bright=60
		color_name=${1#bright_}
	else
		local -i bright=0
		color_name=$1
	fi

	declare -i color=$(form_get color $color_name)
	declare -i style=$(form_get style $2)

	start="$(tty_escape "$style;$((bright + 30 + $color))")"
	reset="$(tty_escape 0)"
	printf "${start}%s${reset}" "$3"
}

shell_join() {
	local arg$()
	printf "%s" "$1"
	shift
	for arg in "$@"; do
		printf " "
		printf "%s" "${arg// /\ }"
	done
}

abort() {
	printf "%s\n" "$(form "red" "normal" "$@")" >&2
	exit 1
}

execute() {
	if ! "$@"; then
		abort "$(printf "Failed during: %s" "$(shell_join "$@")")"
	fi
}

fwhip() {
	printf '%s: %s\n\n' "$(form "bright_blue" "normal" ">>>>>>>>")" "$@"
}

warn() {
	# ring_bell
	printf '%s : %s\n\n' "$(form "bright_red" "normal" "Warning")" "$@"
}

indent() {
	space_count=${2:-4}
	spaces=""
	count=0
	while [[ $count -lt $space_count ]]; do
		spaces+=" "
		((count++))
	done
	printf "${spaces}%s\n" "$1"
}

test_form() {
	# Usage: test_form <assoc_array_name>
	# Pass the NAME of the associative array, not its expanded contents.
	# Requires bash >= 4 for associative arrays and >= 4.3 for nameref (declare -n).
	local name=$1
	# Nameref to the associative array
	local -n _map=$name

	# Determine maximum key width for alignment
	local max=0 k
	for k in "${!_map[@]}"; do
		((${#k} > max)) && max=${#k}
	done

	indent "$(form "bright_yellow" "underline" "Test info:")"
	# Sort keys for stable output
	while IFS= read -r k; do
		local v=${_map[$k]}
		local plain_key=$k
		local colored_key
		colored_key=$(form "yellow" "normal" "$plain_key")

		# Spaces needed after the colored key
		local pad=$((max - ${#plain_key}))
		((pad < 0)) && pad=0

		# Build line: colored_key + pad spaces + " : " + value
		indent "$(printf '%s%*s : %s' "$colored_key" "$pad" '' "$(form "normal" "normal" "$v")")"
	done < <(printf '%s\n' "${!_map[@]}")
	# runtime
	echo
}

min_sec() { printf "%dm %ds" "$((10#$1 / 60))" "$((10#$1 % 60))"; }

# Errors and help
match_command() {
	aliases=("${3}" "${2}")
	for alias in ${aliases[@]}; do
		if [[ "${alias}" == "${1}" ]]; then
			export op="${2}"
		fi
	done
}

command_help() {
	printf '\n%s\n\n' "$(form "cyan" "normal" "$(cat ${CRAFT_HOME_DIR}/config/help/${1}_help.txt)")"
	exit ${2}
}

missing_argument() {
	warn "Invalid option: -$2 requires an argument"
	command_help $1 1
}

invalid_command() {
	warn "Invalid command: $2"
	command_help $1 1
}

invalid_option() {
	warn "Invalid option: -$2"
	command_help $1 1
}

missing_required_option() {
	warn "Missing option: $1 requires \"$2\""
	command_help $1 1
}

runtime() {
	indent "$(form "yellow" "normal" "Runtime: $(min_sec $(($(date +%s) - START)))")"
}

pid() {
	PID=($(lsof -i :$server_port | grep "$server_port (LISTEN)" | awk '{print $2}'))
}

list_properties() {
	count=0
	while IFS="" read -r line || [ -n "$line" ]; do
		if [[ $count -gt 1 ]]; then
			prop=$(echo "${line%=*}" | tr .- _)
			set=$(printf '%s\n' "${line##*=}")
			export $prop="$set"
		fi
		((count++))
	done <"${1}"
}

get_properties() {
	list_properties "${CRAFT_SERVER_DIR}/${server_name}/server.properties"
	list_properties "${CRAFT_SERVER_DIR}/${server_name}/fabric-server-launcher.properties"
}

find_server() {
	if ! [[ -d "${CRAFT_SERVER_DIR}/${1}" ]]; then
		warn "No server named ${1} in ${CRAFT_SERVER_DIR}"
		exit 1
	fi
}

server_status() {

	pid

	# echo "PID: ${PID}, User: ${USER}" >>"${CRAFT_SERVER_DIR}/${server_name}/logs/monitor/$(date '+%Y-%m').log"

	if [ $PID ]; then
		fwhip "\"${server_name}\" Minecraft server running on port: $(form green normal "${server_port}") PID: $(form green normal "${PID}")"
		[[ $1 != "silent" ]] && echo "$(date) : Status: \"${server_name}\" is running on port: ${server_port} PID: ${PID}" >>"${CRAFT_SERVER_DIR}/${server_name}/logs/monitor/$(date '+%Y-%m').log"
		(exit 0)
	else
		warn "\"${server_name}\" is not running"
		[[ $1 != "silent" ]] && echo "$(date) : Status: \"${server_name}\" is not running" >>"${CRAFT_SERVER_DIR}/${server_name}/logs/monitor/$(date '+%Y-%m').log"
		(exit 1)
	fi

}

discord_message() {

	message() {
		cat <<EOF
{
  "embeds":[{
    "title": "${1}",
    "description":"${2}",
    "timestamp":"$(date +'%Y-%m-%dT%H:%M:%S%z')",
    "color":"${3}",
    "author":{
      "name":"Craft CLI - ${4}",
      "url":"https://github.com/stein935/craft"
    }
  }]
}
EOF
	}

	# POST request to Discord Webhook
	curl -H "Content-Type: application/json" -X POST -d "$(message "$1" "$2" "$3" "$4")" $discord_webhook &>/dev/null

}

boolean() {
	case $1 in
	true) echo true ;;
	false) echo false ;;
	*) echo true ;;
	esac
}

# Usage:
# long_running_command &          # start something in background
# bg_pid=$!
# distractor "Working..." $bg_pid # show spinner until it finishes
distractor() {
	local msg="$1"
	local target_pid="${2:-$!}"

	# If no pid or not a TTY just return
	[[ -z "$target_pid" ]] && return 0
	[[ ! -t 1 ]] && {
		wait "$target_pid" 2>/dev/null
		return $?
	}

	# Spinner frames (fallback to simple ASCII if locale has issues)
	local frames=(⠋ ⠙ ⠚ ⠞ ⠖ ⠦ ⠴ ⠲ ⠳ ⠓)
	# Validate unicode support; if not, switch
	printf '%s' "${frames[0]}" | grep -q "?" && frames=('|' '/' '-' '\')

	local i=0
	local delay=0.1

	# Hide cursor
	tput civis 2>/dev/null || true

	while kill -0 "$target_pid" 2>/dev/null; do
		printf "\r%s %s" "$msg" "${frames[i]}"
		((i = (i + 1) % ${#frames[@]}))
		sleep "$delay"
	done

	# Wait to collect exit status
	local rc=0
	wait "$target_pid" 2>/dev/null || rc=$?

	# Clear line
	if command -v tput &>/dev/null; then
		printf "\r"
		tput el 2>/dev/null || true
	else
		# Fallback clear (overwrite with spaces up to terminal width or 120)
		local cols
		cols=$(tput cols 2>/dev/null || echo 120)
		printf "\r%*s\r" "$cols" ""
	fi

	# Show cursor again
	tput cnorm 2>/dev/null || true

	return $rc
}
