#!/usr/bin/env bash

-ls_command() {
	printf '\n%s\n\n' "$(form "cyan" "normal" "$(ls ${CRAFT_SERVER_DIR} | cat -n)")"
	exit 0
}
