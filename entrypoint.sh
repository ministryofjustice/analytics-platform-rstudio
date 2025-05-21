#!/bin/bash
set -e

# Setup user (as you already have)
USER_NAME="${USER:-rstudio}"
export DEFAULT_USER="$USER_NAME"

if id -u 1000 &>/dev/null && [ "$(id -un 1000)" != "$DEFAULT_USER" ]; then
	echo "Removing default user with UID 1000"
	userdel --remove "$(id -un 1000)"
fi

if [ -x /rocker_scripts/default_user.sh ]; then
	echo "Running default_user.sh"
	/rocker_scripts/default_user.sh
else
	echo "default_user.sh not found or not executable" >&2
	exit 1
fi

# Start s6 to run init scripts (including secure-cookie-key-conf)
/init
