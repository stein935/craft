#!/usr/bin/env bash

shellenv_command() {
  if [[ "${PATH}" == *"${CRAFT_HOME_DIR}/bin"* ]]; then
    return
  fi
  echo "export PATH=\"${CRAFT_HOME_DIR}/bin\${PATH+:\$PATH}\";"
  exit 0
}
