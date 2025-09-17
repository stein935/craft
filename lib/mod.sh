#!/usr/bin/env bash

command="mod"
server_name=false
file=false
url=false
list=false
remove=false
test=false

mod_command() {

	[ -z "$1" ] && command_help "$command" 1

	while getopts ":n:p:u:r:lth" opt; do
		case $opt in
		n) server_name="$OPTARG" ;;
		p) file="$OPTARG" ;;
		u) url="$OPTARG" ;;
		l) list=true ;;
		r) remove="$OPTARG" ;;
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
		declare -A test_info=([command]="$command" [server_name]="$server_name" [file]="$file" [list]="$list" [remove]="$remove" [test]="$test")
		test_form test_info
	fi

	mod_server

}

mod_server() {

	if $list; then
		mod_dir="${CRAFT_SERVER_DIR}/${server_name}/mods"
		if [ ! -d "${mod_dir}" ]; then
			warn "\"${server_name}\" mods directory does not exist"
		elif [ -z "$(ls -A "${mod_dir}" 2>/dev/null)" ]; then
			warn "\"${server_name}\" has no mods installed"
		else
			form "cyan" "normal" "$(ls "${mod_dir}" | cat -n)" && echo && echo
		fi
	fi

	if [[ "${remove}" != false ]]; then
		[ ! -f "${CRAFT_SERVER_DIR}/${server_name}/mods/${remove}" ] && warn "Mod not found: ${remove}" && exit 1
		execute "rm" "-f" "${CRAFT_SERVER_DIR}/$server_name/mods/${remove}"
		fwhip "${remove} removed from \"${server_name}\" Minecraft server"
		echo "$(date) : Mod: Removed ${remove} from \"${server_name}\"" >>"${CRAFT_SERVER_DIR}/${server_name}/logs/monitor/$(date '+%Y-%m').log"
	fi

	if [[ "${file}" != false ]]; then
		[ ! -f "${file}" ] && warn "File not found: ${file}" && exit 1
		execute "cp" "${file}" "${CRAFT_SERVER_DIR}/${server_name}/mods"
		fwhip "${file} installed on \"${server_name}\" Minecraft server"
		echo "$(date) : Mod: Added ${file} to \"${server_name}\"" >>"${CRAFT_SERVER_DIR}/${server_name}/logs/monitor/$(date '+%Y-%m').log"
	fi

	[[ "${list}" == false ]] && [[ "${remove}" == false ]] && [[ "${file}" == false ]] && [[ "${url}" == false ]] && missing_required_option "$command" "-l, -r, -p, or -u"

	if [[ "${url}" != false ]]; then
		url_decoded=$(printf '%b' "${url//%/\\x}")
		[ ! -d "${CRAFT_SERVER_DIR}/${server_name}/mods" ] && execute "mkdir" "-p" "${CRAFT_SERVER_DIR}/${server_name}/mods"
		status_code=$(curl -s -o /dev/null -w '%{http_code}' -L "$url")
		if [ "$status_code" -eq 404 ]; then
			warn "URL not found (404): $url"
			$test && runtime && echo
			exit 1
		fi
		curl -L -sS -o "${CRAFT_SERVER_DIR}/${server_name}/mods/${url_decoded##*/}" "$url"
		fwhip "$(form green normal "${url_decoded##*/}") installed on \"${server_name}\" Minecraft server"
		echo "$(date) : Mod: Added ${url_decoded##*/} to \"${server_name}\"" >>"${CRAFT_SERVER_DIR}/${server_name}/logs/monitor/$(date '+%Y-%m').log"
	fi

	$test && runtime && echo
	exit 0

}
