#!/usr/bin/env bash

VERSION_FILE="${CRAFT_HOME_DIR}/version.txt"

-v_command() {
	if [ -f "$VERSION_FILE" ]; then
		printf '\n%s\n\n' "$(form "cyan" "normal" "$(cat "$VERSION_FILE")")"
	else
		warn "version.txt not found."
		exit 1
	fi
}
