#!/bin/bash
set -e

# Use the USER environment variable passed in from Helm to set DEFAULT_USER
USER_NAME="${USER:-rstudio}"
export DEFAULT_USER="$USER_NAME"

# Remove user with UID 1000 if it exists (the default user)
if id -u 1000 &>/dev/null && [ "$(id -un 1000)" != "$DEFAULT_USER" ]; then
    echo "Removing default user with UID 1000"
	userdel --remove "$(id -un 1000)"
fi

if [ -x /rocker_scripts/default_user.sh ]; then
	# Recreate the default user with correct username
	echo "Running default_user.sh"
	/rocker_scripts/default_user.sh
else
    echo "default_user.sh not found or not executable" >&2
    exit 1
fi

exec "$@"
