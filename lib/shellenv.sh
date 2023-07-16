#!/usr/bin/env bash

shellenv_command() {
  if [[ "${PATH}" == *"${CRAFT_PREFIX}/bin"* ]]; then
    return
  fi
  echo "export PATH=\"${CRAFT_PREFIX}/bin\${PATH+:\$PATH}\";"
  exit 0
}
