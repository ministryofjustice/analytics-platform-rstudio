#!/usr/bin/with-contenv sh

# Set secure cookie key so that auth-proxy can pass in the correct cookie
# See load-balancing docs for more inforamtion
# https://docs.rstudio.com/ide/server-pro/latest/load-balancing.html
if [ -z "$SECURE_COOKIE_KEY" ];then
  echo "SECURE_COOKIE_KEY not set"
else
  echo "${SECURE_COOKIE_KEY}"
  echo -n "${SECURE_COOKIE_KEY}" > /var/lib/rstudio-server/secure-cookie-key
  chmod 600 /var/lib/rstudio-server/secure-cookie-key
fi
