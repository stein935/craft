#!/usr/bin/env bash

server_name="test server of doom"

function cleanup {
  craft delete -n "${server_name}" &> /dev/null
}

trap cleanup EXIT

test_command () {
  passed=()
  failed=()

  tests=(

    # help
    "craft -h,false,0"
    "craft -ls,false,0"
    "craft command -h,false,0"
    "craft config -h,false,0"
    "craft create -h,false,0"
    "craft delete -h,false,0"
    "craft mod -h,false,0"
    "craft monitor -h,false,0"
    "craft restart -h,false,0"
    "craft server -h,false,0"
    "craft start -h,false,0"
    "craft status -h,false,0"
    "craft stop -h,false,0"

    # happy path
    "craft create -v 1.19.2 -tn,true,0,ny"
    "craft status -tn,true,1"
    "craft config -tn,true,0,...........................................................n"
    "craft start -tn,true,0"
    "craft server -tn,true,0"
    "craft status -tn,true,0"
    "craft command -c /seed -tn,true,0"
    "craft monitor -tn,true,0"
    "craft stop -tn,true,0"
    "craft monitor -tn,true,1"
    "craft server -tn,true,0"
    "crontab -e,false,0"
    "craft stop -tn,true,0"
    "crontab -e,false,0"
    "craft delete -tn,true,0,y"
  )

  bar () { printf '\n%*s\n\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' - ; }
  test_pass () {
    passed+=("$(printf '%s\texpected: %s : result: %s\tcommand: %s' "$((i+1))" "${test[2]}" "${status}" "${command_string}")")
  }
  test_fail () {
    failed+=("$(printf '%s\texpected: %s : result: %s\tcommand: %s' "$((i+1))" "${test[2]}" "${status}" "${tty_red}${command_string}${tty_reset}")")
  }

  bar
  for ((i = 0; i < ${#tests[@]}; i++)); do

    IFS="," read -a test <<< "${tests[$i]}"

    ! $(boolean ${test[1]}) && command_string="${test[0]}" || command_string="${test[0]} \"${server_name}\""

    fwhip "Test $((i+1)): ${command_string}"
    echo

    if [[ ${test[1]} == "false" ]]; then 
      ${test[0]}
      status="$?"
    elif [ -z ${test[3]} ]; then
      ${test[0]} "${server_name}"
      status="$?"
    else
      printf "${test[3]//./$'\n'}" | ${test[0]} "${server_name}"
      status="$?"
    fi

    [[ "${status}" == "${test[2]}" ]] && test_pass || test_fail
    bar

  done

  [ ${#passed[@]} -gt 0 ] && fwhip "Passed Tests:" && echo
  for pass in "${passed[@]}"; do
    indent "${pass}"
  done

  [ ${#failed[@]} -gt 0 ] && [ ${#passed[@]} -gt 0 ] && bar

  [ ${#failed[@]} -gt 0 ] && warn "Failed Tests:" && echo
  for fail in "${failed[@]}"; do
    indent "${fail}"
  done
  bar
  exit 0
 
}