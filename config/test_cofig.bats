@test "-h, --help prints craft CLI usage" {
  
  run craft -h
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage"* ]]

  run craft --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage"* ]]

}

@test "-v, --version prints craft CLI version" {
  
  run craft -v
  [ "$status" -eq 0 ]
  [[ "$output" == *"Craft CLI version"* ]]

  run craft --version
  [ "$status" -eq 0 ]
  [[ "$output" == *"Craft CLI version"* ]]

}

@test "create new server named \"test-$(date// /_)\" with default versions" {
  
  run bash -c 'echo "y" | sudo craft create -n "test-$(date// /_)"'
  [ "$status" -eq 0 ]
  [[ "$output" == *"\"test-$(date// /_)\" has been created!"* ]]

}

@test "-ls, --list prints all servers" {

  run craft -ls
  [ "$status" -eq 0 ]

}

