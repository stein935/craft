#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

load "$CRAFT_LIB/common.sh"

setup() {

  server_name="test-1.20.4"
  # BATS_TEST_RETRIES=5

}

teardown() { 
  echo >&3
}

## Tests

@test "$(number)	delete" {

	test_desc_form true "sudo craft delete -n $server_name" "Cleanup"
	run -0 bash -c "echo 'y' | sudo craft delete -n $server_name"
	check_output "Deleting dir: /opt/craft/servers/"

}

@test "$(number)	Invalid command" {

	test_desc_form false "craft bad" 
	run -1 craft bad
	check_output "Invalid command: bad"

}

@test "$(number)	-h prints craft CLI usage" {

	test_desc_form true "craft"
	run -1 craft
	check_output "Usage"

  test_desc_form true "craft -h"
	run -0 craft -h
	check_output "Usage"

  test_desc_form true "craft --help" "-h alias"
	run -0 craft --help
	check_output "Usage"

}

@test "$(number)	-v, --version prints craft CLI version" {

  test_desc_form true "craft -v"
	run -0 craft -v
	check_output "Craft"

  test_desc_form true "craft --version" "-v alias"
	run -0 craft --version
	check_output "Craft"

}

@test "$(number)	create new server" { 
  
  test_desc_form false "sudo craft create"
	run -1 sudo craft create
	check_output "Usage"

  test_desc_form true "sudo craft create -h"
  run -0 sudo craft create -h
  check_output "Usage"

  test_desc_form false "sudo craft create -n" "No name provided"
  run -1 sudo craft create -n 
	check_output "Invalid option: -n requires an argument"

  test_desc_form false "sudo craft create -g" "No Minecraft version provided"
  run -1 sudo craft create -g
  check_output "Invalid option: -g requires an argument"

  test_desc_form false "sudo craft create -l" "No Fabric loader version provided"
  run -1 sudo craft create -l
  check_output "Invalid option: -l requires an argument"

  test_desc_form false "sudo craft create -xn $server_name" "Invalid option"
  run -1 sudo craft create -xn $server_name
  check_output "Invalid option: -x"

  test_desc_form true "sudo craft create -n $server_name -g '1.20.4' -l '0.15.11'"
	run -0 bash -c "echo 'y' | sudo craft create -n $server_name -g '1.20.4' -l '0.15.11'"
	check_output "\"$server_name\" has been created!"
  [ -f "$CRAFT_SERVER_DIR/$server_name/versions/1.20.4/server-1.20.4.jar" ]
  [[ "$(cat "$CRAFT_SERVER_DIR/$server_name/eula.txt" | grep "eula=" | cut -d= -f2)" == "true" ]]

  test_desc_form false "sudo craft create -n $server_name" "Already exists"
	run -1 sudo craft create -n $server_name
	check_output "\"$server_name\" already exists."

}

@test "$(number)	-ls, --list prints all servers" {

  test_desc_form true "craft -ls"
	run -0 craft -ls
	check_output "$server_name"

  test_desc_form true "craft --list" "-ls alias"
	run -0 craft --list
	check_output "$server_name"

}

@test "$(number)	config $server_name" {

  test_desc_form true "sudo craft config -h"
  run -0 sudo craft config -h
  check_output "Usage"

  test_desc_form false "sudo craft config" "No name provided"
  run -1 sudo craft config
  check_output "Usage"

  test_desc_form false "sudo craft config -n" "No name provided"

  test_desc_form true "sudo craft config -n $server_name" "Set max memory to 4G and set logo.txt"
	run -0 bash -c "printf '4G\ny%s\n' "$CRAFT_HOME_DIR/config/logo.txt" | sudo -E CONFIG_FILE=fabric-server-launcher.properties CONFIG_PROPERTY=server_max_mem craft config -n $server_name"
  [[ "$(cat "$CRAFT_SERVER_DIR/$server_name/fabric-server-launcher.properties" | grep server_max_mem | cut -d= -f2)" == "4G" ]]
	[ -f "$CRAFT_SERVER_DIR/$server_name/logo.txt" ]

}

@test "$(number)	mod with url" {

  test_desc_form true "sudo craft mod -n $server_name -u <url>"
	run -0 sudo craft mod -n $server_name -u "https://cdn.modrinth.com/data/P7dR8mSH/versions/BPX6fK06/fabric-api-0.97.3%2B1.20.4.jar"
	check_output "${url_decoded##*/:?assigned in common.sh} installed on \"$server_name\" Minecraft server"
	[ -f "$CRAFT_SERVER_DIR/$server_name/mods/fabric-api-0.97.3+1.20.4.jar" ]

}

@test "$(number)	mod with path" {

  test_desc_form true "sudo craft mod -n $server_name -p <path>"
	sudo curl -L -sS -o "$CRAFT_SERVER_DIR/$server_name/sodium-fabric-0.5.8+mc1.20.4.jar" "https://cdn.modrinth.com/data/AANobbMI/versions/4GyXKCLd/sodium-fabric-0.5.8%2Bmc1.20.4.jar"
	run -0 sudo craft mod -n $server_name -p "$CRAFT_SERVER_DIR/$server_name/sodium-fabric-0.5.8+mc1.20.4.jar"
	check_output "$CRAFT_SERVER_DIR/$server_name/sodium-fabric-0.5.8+mc1.20.4.jar installed on \"$server_name\" Minecraft server"
	[ -f "$CRAFT_SERVER_DIR/$server_name/mods/sodium-fabric-0.5.8+mc1.20.4.jar" ]
	sudo rm -f "$CRAFT_SERVER_DIR/$server_name/sodium-fabric-0.5.8+mc1.20.4.jar"

}

@test "$(number)	mod list" {

  test_desc_form true "sudo craft mod -n $server_name -l"
	run -0 sudo craft mod -n $server_name -l
	check_output "fabric-api-0.97.3+1.20.4.jar"
	check_output "sodium-fabric-0.5.8+mc1.20.4.jar"

}

@test "$(number)	mod remove" {

  test_desc_form true "sudo craft mod -n $server_name -r <mod>"
	run -0 sudo craft mod -n $server_name -r "fabric-api-0.97.3+1.20.4.jar"
	[ ! -f "$CRAFT_SERVER_DIR/$server_name/mods/fabric-api-0.97.3+1.20.4.jar" ]

}

@test "$(number)	status not running" {

  test_desc_form true "sudo craft status" "Check all servers"
	run -0 sudo craft status
	check_output "\"$server_name\" is not running"

  test_desc_form false "sudo craft status -n $server_name" "Check $server_name"
	run -1 sudo craft status -n $server_name
	check_output "\"$server_name\" is not running"

}

@test "$(number)	start $server_name" {

  test_desc_form true "sudo craft start -n $server_name"
	run -0 sudo craft start -n $server_name
	check_output "\"$server_name\" Minecraft server running on port:"

}

@test "$(number)	status running" {

  test_desc_form true "sudo craft status" "Check all servers"
	run -0 sudo craft status
	check_output "\"$server_name\" Minecraft server running on port:"

  test_desc_form true "sudo craft status -n $server_name" "Check $server_name"
	run -0 sudo craft status -n $server_name
	check_output "\"$server_name\" Minecraft server running on port:"

}

@test "$(number)	restart $server_name" {

  test_desc_form true "sudo craft restart -n $server_name"
	run -0 sudo craft restart -n $server_name
	check_output "\"$server_name\" Minecraft server stopped"
	check_output "\"$server_name\" Minecraft server running on port:"

}

@test "$(number)	command send to $server_name" {

  test_desc_form true "sudo craft command -n $server_name -c seed"
	run -0 sudo craft command -n $server_name -c seed
	check_output "Seed"

}

@test "$(number)	stop $server_name" {

  test_desc_form true "sudo craft stop -n $server_name"
	run -0 sudo craft stop -n $server_name
	check_output "\"$server_name\" Minecraft server stopped"

}
