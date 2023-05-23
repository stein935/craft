CRAFT_PATH=/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
CRAFT_PREFIX=/usr/local
CRAFT_REPOSITORY=/usr/local/craft

shellenv-command() {
  if [[ "${CRAFT_PATH%%:"${CRAFT_PREFIX}"/sbin*}" == "${CRAFT_PREFIX}/bin" ]]
  then
    return
  fi

  if [[ -n "$1" ]]
  then
    CRAFT_SHELL_NAME="$1"
  else
    CRAFT_SHELL_NAME="$(/bin/ps -p "${PPID}" -c -o comm=)"
  fi

  echo "export CRAFT_PREFIX=\"${CRAFT_PREFIX}\";"
  echo "export CRAFT_REPOSITORY=\"${CRAFT_REPOSITORY}\";"
  echo "export PATH=\"${CRAFT_PREFIX}/bin:${CRAFT_PREFIX}/sbin\${PATH+:\$PATH}\";"
  echo "export MANPATH=\"${CRAFT_PREFIX}/share/man\${MANPATH+:\$MANPATH}:\";"
  echo "export INFOPATH=\"${CRAFT_PREFIX}/share/info:\${INFOPATH:-}\";"
     
}