#!/usr/bin/env bash

-ls_command() {
	ls ${CRAFT_SERVER_DIR} | cat -n
	exit 0
}
