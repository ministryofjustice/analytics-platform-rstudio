#!/bin/bash
set -e

echo "[entrypoint] Starting setup..."
USER_NAME="${USER:-rstudio}"
export DEFAULT_USER="$USER_NAME"

if id -u 1000 &>/dev/null && [ "$(id -un 1000)" != "$DEFAULT_USER" ]; then
	echo "[entrypoint] Removing default user with UID 1000..."
	userdel --remove "$(id -un 1000)" || echo "[entrypoint] Warning: userdel failed"
fi

echo "[entrypoint] About to run default_user.sh..."
if [ -x /rocker_scripts/default_user.sh ]; then
	/rocker_scripts/default_user.sh || { echo "[entrypoint] default_user.sh failed!"; exit 1; }
	echo "[entrypoint] default_user.sh completed."
else
	echo "[entrypoint] ERROR: default_user.sh not found or not executable" >&2
	exit 1
fi

echo "[entrypoint] Checking for /init..."
if [ -x /init ]; then
	echo "[entrypoint] /init found and executable. Starting s6..."
	/init
else
	echo "[entrypoint] ERROR: /init not found or not executable" >&2
	ls -l /init || echo "[entrypoint] /init does not exist"
	exit 1
fi
