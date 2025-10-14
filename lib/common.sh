#!/usr/bin/env bash

# Bits
ring_bell() { [ -t 1 ] && printf "\a"; }

# string formatters
tty_escape() { printf "\033[%sm" "$1"; } || tty_escape() { :; }

strip_ansi() {
	# Reads from stdin and outputs to stdout
	sed -r 's/\x1B\[[0-9;]*[mK]//g'
}

form() {

	# ANSI color codes
	# shellcheck disable=SC2034  # color used indirectly via nameref in form_get
	local -A color=(
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
	local -A style=(
		[normal]=0
		[bold]=1
		[dim]=2
		[italic]=3
		[underline]=4
		[blink]=5
		[reverse]=7
		[hidden]=8
	)

	if [[ $1 == bright_* ]]; then
		local -i bright=60
		color_name=${1#bright_}
	else
		local -i bright=0
		color_name=$1
	fi

	# Retrieve numeric codes without shadowing associative arrays
	local -i color_code
	color_code=$(echo "${color[$color_name]}")

	local -i style_code
	style_code=$(echo "${style[$2]}")

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

	local space_count=${2:-4}
	local spaces=""

	for ((i = 0; i < space_count; i++)); do
		spaces+=" "
	done

	printf "%s%s\n" "$spaces" "$1"

}

rm_line() {
	printf "\033[1A\033[2K"
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

test_desc_form() {

	local type
	$1 && type="green" || type="red"
	local comment
	[ -n "$3" ] && comment="$(form yellow dim "# $3")"
	indent "$(form $type normal "") $(form cyan dim "$2") $comment" 12 >&3

}

check_output() {
	[[ "$(echo "${output:?Defined by bats}" | strip_ansi)" == *"$1"* ]]
}

number() {
	form blue normal "$BATS_TEST_NUMBER"
}

use_fzf() {

	local prompt="$1"

	if command -v fzf >/dev/null 2>&1; then
		# shellcheck disable=SC2016
		fzf --style full \
			--height 40% \
			--layout=reverse \
			--padding 1,2 \
			--input-label ' Select ' \
			--bind 'result:transform-list-label:
            if [[ -z $FZF_QUERY ]]; then
              echo " $FZF_MATCH_COUNT items "
            else
              echo " $FZF_MATCH_COUNT matches for [$FZF_QUERY] "
            fi
            ' \
			--bind 'ctrl-r:change-list-label( Reloading the list )+reload(sleep 2; git ls-files)' \
			--color 'list-border:green,list-label:bright-green' \
			--color 'input-border:cyan,input-label:bright-cyan' \
			--color 'pointer:yellow' \
			--color 'prompt:cyan' \
			--prompt=" $prompt: "
	else
		# Fallback to bash built-in select
		local items=()
		while IFS= read -r line; do
			items+=("$line")
		done

		if [ ${#items[@]} -eq 0 ]; then
			warn "No items to select from"
			return 1
		fi

		PS3="$(form "cyan" "normal" "$prompt by entering the number: ")"
		select choice in "${items[@]}" "Cancel"; do
			if [[ "$choice" == "Cancel" ]]; then
				return 1
			elif [[ -n "$choice" ]]; then
				echo "$choice"
				break
			else
				warn "Invalid selection. Please try again."
			fi
		done </dev/tty # <-- Add this to read from terminal
	fi

}

min_sec() { printf "%dm %ds" "$((10#$1 / 60))" "$((10#$1 % 60))"; }

# Errors and help
replace_alias_args() {

	local -n arr="$1"
	shift
	local out=()

	for arg in "$@"; do
		local found=false
		for alias in "${!arr[@]}"; do
			local replacement=${arr[$alias]}
			if [[ "$arg" == "$alias" ]]; then
				out+=("$replacement")
				found=true
				break
			fi
		done
		! $found && out+=("$arg")
	done
	printf '%s\n' "${out[@]}"

}

command_help() {

	printf '\n%s\n\n' "$(form "cyan" "normal" "$(cat "${CRAFT_HOME_DIR}"/config/help/"${1}"_help.txt)")"
	exit "$2"

}

missing_argument() {

	warn "Missing argument: -$2 requires an argument"
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

players() {
	local status
	status=$(mcstatus "127.0.0.1:${server_port:?server_port must be set by parent script}" json)
	local online
	online=$(echo "$status" | jq -r '.status.players.online')
	local max
	max=$(echo "$status" | jq -r '.status.players.max')
	readarray -t players < <(echo "$status" | jq -r '.status.players.sample // [] | .[].name' | sort -u)
	local string
	[[ $online -gt 0 ]] && string=": $(form green normal "${players[@]// /, }")" || string=""
	printf 'Players [%s/%s]%s\n' "$online" "$max" "$string"
}

server_on() {

	local -i time
	time=${1:-20}

	export PID
	local PIPE
	local PORT="${server_port:?server_port must be set by parent script}"
	local SERVER_NAME="${server_name:?server_port must be set by parent script}"

	for ((i = 0; i <= time; i++)); do
		PID=$(lsof -i :"$PORT" | grep "$PORT (LISTEN)" | awk '{print $2}')
		# shellcheck disable=SC2015
		[ -n "$PID" ] && PIPE=$(lsof -p "$PID" | grep "${SERVER_NAME}/command-pipe" | awk '{print $2}')
		if [ -n "$PID" ] && [ -n "$PIPE" ] && [[ "$PID" == "$PIPE" ]]; then
			fwhip "$(form "bright_cyan" "italic" "\"${SERVER_NAME}\"") Minecraft server running on port: $(form green normal "$PORT"), PID: $(form green normal "$PID"), $(players)"
			return 0
		else
			[[ $i != 0 ]] && sleep 1
		fi
	done
	warn "$(form "bright_cyan" "italic" "\"${SERVER_NAME}\"") is not running"
	return 1

}

server_off() {

	local -i time
	time=${1:-20}

	export PID
	local PORT="${server_port:?server_port must be set by parent script}"
	local SERVER_NAME="${server_name:?server_port must be set by parent script}"

	for ((i = 0; i <= time; i++)); do
		PID=$(lsof -i :"$PORT" | grep "$PORT (LISTEN)" | awk '{print $2}')
		# shellcheck disable=SC2015
		if ! [ -n "$PID" ]; then
			warn "$(form "bright_cyan" "italic" "\"${SERVER_NAME}\"") is not running"
			return 0
		else
			! [[ $i == 0 ]] && sleep 1
		fi
	done
	fwhip "$(form "bright_cyan" "italic" "\"${SERVER_NAME}\"") Minecraft server running on port: $(form green normal "$PORT") PID: $(form green normal "$PID")"
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

	if ! [[ -d "${CRAFT_SERVER_DIR}/$server_name" ]]; then
		warn "Server not found: $server_name"
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
