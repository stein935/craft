#!/usr/bin/env bash

-h_command() {
	command_help "${command:?command must be defined by parent}" "0"
	exit 0
}
