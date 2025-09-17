#!/usr/bin/env bash

: <<'END_COMMENT'
Tests:
	Valid commands:
		craft -h
		craft --help
	Invalid commands:
		craft -x -h
END_COMMENT

-h_command() {
	command_help "${command}" "0"
	exit 0
}
