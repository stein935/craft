#!/usr/bin/env bash

test_command() {

	echo
	# Enable sudo
	sudo ls >/dev/null
	bats --timing "$CRAFT_HOME_DIR/config/test_config.bats"

}
