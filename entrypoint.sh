#!/bin/bash
set -e

# Use the USER environment variable passed in from Helm to set DEFAULT_USER
export DEFAULT_USER="${USER:-rstudio}"

# Remove user with UID 1000 if it exists (the default user)
if id -u 1000 &>/dev/null; then
	userdel --remove "$(id -un 1000)"
fi

# Recreate the default user with correct username
/rocker_scripts/default_user.sh

exec "$@"
