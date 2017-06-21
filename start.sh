#!/bin/bash
set -ex

GROUP=staff
USER_UID=1001

useradd -g $GROUP -u $USER_UID -d /home/$USER $USER

echo "auth-proxy-sign-in-url=https://${USER}-rstudio.${TOOLS_DOMAIN}/logout" >> /etc/rstudio/rserver.conf
echo "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}" >> /usr/local/lib/R/etc/Renviron
echo "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}" >> /usr/local/lib/R/etc/Renviron
echo "AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}" >> /usr/local/lib/R/etc/Renviron

/usr/lib/rstudio-server/bin/rserver --server-daemonize 0 --auth-none=1
