#!/usr/bin/env bash

config_command() {

	export command="config"
	export server_name=false
	test=false

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

	config_server

}

config_server() {

	local propfiles
	propfiles=("${CRAFT_SERVER_DIR}/${server_name}/"*.properties)
	local selected
	selected=$(printf "%s\n" "${propfiles[@]##*/}" | fzf)

	fwhip "Configuring ${selected}"
	read_properties "/${CRAFT_SERVER_DIR}/${server_name}/${selected}"

	while true; do
		read -p "$(fwhip "Do you want to add a text art logo to \"${server_name}?\"? (y/n) : ")" -n 1 -r
		echo && echo
		if [[ $REPLY =~ ^[Yy]$ ]]; then
			read -rp "Path to file : " ans
			ans=$(echo "$ans" | tr -d '~')
			cp "${HOME}${ans}" "${CRAFT_SERVER_DIR}/${server_name}/logo.txt"
			break
		elif [[ $REPLY =~ ^[Nn]$ ]]; then
			break
		else
			warn "Please enter y or n"
		fi
	done

	fwhip "Configuration complete"
	$test && echo && runtime && echo
	exit 0

}

read_properties() {

	local file=$1
	local -a properties_raw
	mapfile -t properties_raw <"$file"
	local -A properties

	for line in "${properties_raw[@]}"; do
		key=$(echo "${line%=*}" | tr -d '\n')
		val=$(echo "${line##*=}" | tr -d '\n')
		if [[ "${line:0:1}" != "#" && "${line:0:2}" != "##" ]]; then
			properties["$key"]="$val"
		fi
	done

	selected=$(for key in "${!properties[@]}"; do
		printf "%s=%s\n" "$key" "${properties[$key]}"
	done | fzf)

	# Extract key and value from selection
	sel_key="${selected%%=*}"
	sel_val="${selected#*=}"

	# Prompt user for new value
	read -rp "$sel_key (Current: \"$sel_val\"): " input
	printf "\033[1A\033[2K"

	# If user entered a new value, update the file
	if [[ -n "$input" && "$input" != "$sel_val" ]]; then
		# Update the value in the array
		properties["$sel_key"]="$input"
		# Write back to file, preserving comments and order
		true >"$file"
		for line in "${properties_raw[@]}"; do
			if [[ "${line:0:1}" == "#" || "${line:0:2}" == "##" ]]; then
				echo "$line" >>"$file"
			else
				key=$(echo "${line%=*}" | tr -d '\n')
				if [[ "$key" == "$sel_key" ]]; then
					echo "$key=$input" >>"$file"
				else
					echo "$line" >>"$file"
				fi
			fi
		done
		fwhip "Updated $(form "bright_green" "italic" "$sel_key") to $(form "bright_green" "italic" "$input".)"
	else
		warn "No change made to $sel_key."
	fi

}
