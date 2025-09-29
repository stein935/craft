#!/usr/bin/env bash

-ls_command() {
	# Use find to list only files/directories at top level, handle special characters (BSD/macOS compatible)
	server_list=$(find "${CRAFT_SERVER_DIR}" -mindepth 1 -maxdepth 1 -exec basename {} \; | cat -n)
	printf '\n%s\n\n' "$(form "cyan" "normal" "$server_list")"
	exit 0
}
