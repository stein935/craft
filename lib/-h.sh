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
	command_help "${command:?command must be defined by parent}" "0"
	exit 0
}
