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
	printf '%s %s\n\n' "$(form "bright_blue" "normal" "▶")" "$@"
}

warn() {
	# ring_bell
	printf '%s %s\n\n' "$(form "bright_red" "normal" "✕")" "$@"
}

send() {
	printf '%s %s\n\n' "$(form "bright_yellow" "normal" "")" "$@"
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
replace_alias_args() {
	local alias="$1"
	local replacement="$2"
	shift 2
	local out=()
	for arg in "$@"; do
		if [[ "$arg" == "$alias" ]]; then
			out+=("$replacement")
		else
			out+=("$arg")
		fi
	done
	printf '%s\n' "${out[@]}"
}

command_help() {
	printf '\n%s\n\n' "$(form "cyan" "normal" "$(cat ${CRAFT_HOME_DIR}/config/help/${1}_help.txt)")"
	exit $2
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
	wait_time=${2:-10}
	up=${1:-true}
	local pid
	if $up; then
		while [ $wait_time -gt 0 ]; do
			pid=$(lsof -i :$server_port | grep "$server_port (LISTEN)" | awk '{print $2}')
			if [[ -n "$pid" ]]; then
				printf '%s' "$pid"
				return 0
			else
				sleep 1
				((wait_time--))
			fi
		done
	else
		while [ $wait_time -gt 0 ]; do
			pid=$(lsof -i :$server_port | grep "$server_port (LISTEN)" | awk '{print $2}')
			if ! [[ -n "$pid" ]]; then
				return 0
			else
				sleep 1
				((wait_time--))
			fi
		done
	fi
	return 1
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

	local pid
	pid=$(pid)

	if [[ -n "$pid" ]]; then
		fwhip "$(form "bright_cyan" "italic" "\"${server_name}\"") Minecraft server running on port: $(form green normal "${server_port}") PID: $(form green normal "$pid")"
	else
		warn "\"${server_name}\" is not running"
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
