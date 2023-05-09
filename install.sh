#!/bin/bash
# We don't need return codes for "$(command)", only stdout is needed.
# Allow `[[ -n "$(command)" ]]`, `func "$(command)"`, pipes, etc.
# shellcheck disable=SC2312

set -u

abort() {
  printf "%s\n" "$@" >&2
  exit 1
}

# Fail fast with a concise message when not using bash
# Single brackets are needed here for POSIX compatibility
# shellcheck disable=SC2292
if [ -z "${BASH_VERSION:-}" ]
then
  abort "Bash is required to interpret this script."
fi

# Check if script is run with force-interactive mode in CI
if [[ -n "${CI-}" && -n "${INTERACTIVE-}" ]]
then
  abort "Cannot run force-interactive mode in CI."
fi

# Check if both `INTERACTIVE` and `NONINTERACTIVE` are set
# Always use single-quoted strings with `exp` expressions
# shellcheck disable=SC2016
if [[ -n "${INTERACTIVE-}" && -n "${NONINTERACTIVE-}" ]]
then
  abort 'Both `$INTERACTIVE` and `$NONINTERACTIVE` are set. Please unset at least one variable and try again.'
fi

# Check if script is run in POSIX mode
if [[ -n "${POSIXLY_CORRECT+1}" ]]
then
  abort 'Bash must not run in POSIX mode. Please unset POSIXLY_CORRECT and try again.'
fi



# script_pwd=$(pwd)
# if [ -d $HOME/bin/craft ]; then
#   echo "craft is already installed on this machine"
# else
#   mkdir -p $HOME/bin/craft && cd $HOME/bin/craft
#   echo "Installing craft"
#   mkdir lib
#   cp -r $script_pwd/lib/* ./lib
#   cp $script_pwd/craft .
#   echo "Adding craft to bash commands"
#   current_profile=""
#   if [ ! -e "${HOME}/.bash_profile" ]; then
#     touch $HOME/.bash_profile
#     current_profile=$(cat $HOME/.profile)
#   else
#     current_profile=$(sed '/export PATH/d' $HOME/.bash_profile)
#   fi
#   printf '%s\n' "export PATH=${HOME}/bin/craft:${PATH}" \
#                 "$current_profile" > $HOME/.bash_profile
#   echo "Install complete"
# fi