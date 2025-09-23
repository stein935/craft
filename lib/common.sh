#!/usr/bin/env bash

# Bits
ring_bell() { [ -t 1 ] && printf "\a"; }

# string formatters
[ -t 1 ] && tty_escape() { printf "\033[%sm" "$1"; } || tty_escape() { :; }

# ANSI color codes
# shellcheck disable=SC2034  # color used indirectly via nameref in form_get
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
# shellcheck disable=SC2034  # style used indirectly via nameref in form_get
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

	# Retrieve numeric codes without shadowing associative arrays
	local -i color_code
	color_code=$(form_get color "$color_name")
	local -i style_code
	style_code=$(form_get style "$2")

	start="$(tty_escape "$style_code;$((bright + 30 + color_code))")"
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

version_ge() {
	# Returns 0 if $1 >= $2, 1 otherwise
	[ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" = "$2" ]
}

abort() {
	printf "%s\n" "$(warn "$@")" >&2
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
	printf '\n%s\n\n' "$(form "cyan" "normal" "$(cat "${CRAFT_HOME_DIR}"/config/help/"${1}"_help.txt)")"
	exit "$2"
}

missing_argument() {
	warn "Invalid option: -$2 requires an argument"
	command_help "$1" 1
}

invalid_command() {
	warn "Invalid command: $2"
	command_help "$1" 1
}

invalid_option() {
	warn "Invalid option: -$2"
	command_help "$1" 1
}

missing_required_option() {
	warn "Missing option: $1 requires \"$2\""
	command_help "$1" 1
}

runtime() {
	time=$(min_sec $(($(date +%s) - "${START:?START must be set by parent script}")))
	indent "$(form "yellow" "normal" "Runtime: $time")"
}

pid() {

	local time
	local time=${2:-10}
	local up=${1:-true}

	PID=""
	local port="${server_port:?server_port must be set by parent script}"

	if $up; then
		while [ "$time" -gt 0 ]; do
			PID=$(lsof -i :"$port" | grep "$port (LISTEN)" | awk '{print $2}')
			if [[ -n "$PID" ]]; then
				break
			else
				sleep 1
				((time--))
			fi
		done
	else
		while [ "$time" -gt 0 ]; do
			PID=$(lsof -i :"$port" | grep "$port (LISTEN)" | awk '{print $2}')
			if ! [[ -n "$PID" ]]; then
				break
			else
				sleep 1
				((time--))
			fi
		done
	fi
}

server_status() {

	# Get the server PID safely (quoted to prevent word splitting)
	pid "$@"

	if [[ -n "$PID" ]]; then
		local pipe
		pipe=$(lsof -p "$PID" | grep "${server_name:?server_name must be set by parent script}/command-pipe" | awk '{print $2}')
		if [[ -n "$pipe" ]]; then
			fwhip "$(form "bright_cyan" "italic" "\"${server_name}\"") Minecraft server running on port: $(form green normal "${server_port}") PID: $(form green normal "$PID")"
			return 0
		fi
	fi
	warn "$(form "bright_cyan" "italic" "\"${server_name}\"") is not running"
	return 1

}

list_properties() {
	count=0
	while IFS="" read -r line || [ -n "$line" ]; do
		if [[ $count -gt 1 ]]; then
			prop=$(echo "${line%=*}" | tr .- _)
			set=$(printf '%s\n' "${line##*=}")
			export "$prop"="$set"
		fi
		((count++))
	done <"${1}"
}

get_properties() {
	list_properties "${CRAFT_SERVER_DIR}/${server_name:?server_name must be set by parent script}/server.properties"
	list_properties "${CRAFT_SERVER_DIR}/${server_name:?server_name must be set by parent script}/fabric-server-launcher.properties"
}

find_server() {
	if ! [[ -d "${CRAFT_SERVER_DIR}/${1}" ]]; then
		warn "No server named ${1} in ${CRAFT_SERVER_DIR}"
		exit 1
	fi
}
check_java() {

	local game
	game=$1

	if ! command -v java >/dev/null 2>&1; then
		echo "Java is not installed."
		exit 1
	fi

	local java_version
	java_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d. -f1)

	# Determine required Java version
	local required_java
	if version_ge "$game" "1.20.5"; then
		required_java=21
	elif version_ge "$game" "1.18.2"; then
		required_java=17
	elif version_ge "$game" "1.17.2"; then
		required_java=16
	else
		required_java=8
	fi

	if [ "$java_version" -eq "$required_java" ]; then
		return 0
	else
		local found_java
		found_java=$(/usr/libexec/java_home -V 2>&1 | grep -E " $required_java(\.|$)")
		if [ -z "$found_java" ]; then
			warn "Required Java $required_java not found via /usr/libexec/java_home."
			return 1
		fi
		JAVA_HOME=$(/usr/libexec/java_home -v "$required_java")
		export JAVA_HOME
		export PATH="$JAVA_HOME/bin:$PATH"
		warn "Minecraft $game requires Java $required_java; overriding detected Java $java_version"
		return 0
	fi

}

discord_message() {

	message() {
		cat <<-EOF
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
	curl -H "Content-Type: application/json" -X POST -d "$(message "$1" "$2" "$3" "$4")" "${discord_webhook:?discord_webhook must be set by parent script}" &>/dev/null

}

boolean() {
	case $1 in
	true) echo true ;;
	false) echo false ;;
	*) echo true ;;
	esac
}
