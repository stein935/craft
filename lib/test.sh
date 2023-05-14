#!/bin/bash

passed=()
failed=()
tests=(
    "craft -h"
    "craft -BAD"
  )

. "${craft_home_dir}/lib/common.sh"

# Craft CLI 
# Test all commands 

test_report () {

  ohai "Passed tests:"
  printf "%s\n" "${passed[@]}"

  ohai "Failed tests:"
  printf "%s\n" "${failed[@]}"

}

run_test () {

  echo "Running ${test}"
  $test &> /dev/null  &
  status=$?
  echo "$status"
  wait
  if [[ "$status" == "0" ]]; then 
    passed+=("$test")
  else 
    failed+=("$test")
  fi

}

test_command () {

  for test in "${tests[@]}"
  do 
    run_test test
  done

  test_report

}