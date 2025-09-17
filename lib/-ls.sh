#!/usr/bin/env bash

: <<'END_COMMENT'
Tests:
	Valid commands:
		craft -ls
		craft --list
	Invalid commands:
		craft -x -ls
END_COMMENT

-ls_command() {
	printf '\n%s\n\n' "$(form "cyan" "normal" "$(ls ${CRAFT_SERVER_DIR} | cat -n)")"
	exit 0
}
