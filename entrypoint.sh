#!/bin/bash
set -e

# Setup user (as you already have)
USER_NAME="${USER:-rstudio}"
export DEFAULT_USER="$USER_NAME"

# Start s6 to run init scripts (including secure-cookie-key-conf)
/init
