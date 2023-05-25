#!/bin/bash

shellenv-command() {
  if [[ "${PATH}" == *"${CRAFT_PREFIX}/bin"* ]]
  then
    return
  fi

  echo "export PATH=\"${CRAFT_PREFIX}/bin\${PATH+:\$PATH}\";"
}