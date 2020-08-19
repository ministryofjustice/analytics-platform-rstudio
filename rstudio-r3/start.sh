#!/usr/bin/env bash
set -ex

GROUP=staff
USER_UID=1001
export HOME="/home/$USER"

function cleanup() {
 rm -rf "$HOME/.conda/envs/rstudio"
}
trap cleanup ERR

function init_user() {
  if [ "$(id -u "$USER" 2>/dev/null)" != $USER_UID ]; then
      useradd -g $GROUP -u $USER_UID -d "/home/$USER" "$USER" || true
  fi

  # this is only for running locally - in-cluster, home directories are
  # provided via NAS
  echo "${USER}:${USER}" | chpasswd
  if [ ! -d "/home/$USER" ]; then
      mkdir -p "/home/$USER"
      chown "${USER}:${GROUP}" -R "/home/$USER/"
  fi
}

function init_conda() {
  ## if user has ~/.bashrc make sure conda is added to that

  CONDA_SNIPPET='[[ -f /opt/conda/etc/profile.d/conda.sh ]] && . /opt/conda/etc/profile.d/conda.sh'
  CONDA_ENV_ACTIVATE='[[ -v RSTUDIO ]] && conda activate rstudio'

  grep -q -x -F "$CONDA_SNIPPET" "$HOME/.bashrc" || echo "$CONDA_SNIPPET" >> "$HOME/.bashrc"
  grep -q -x -F "$CONDA_ENV_ACTIVATE" "$HOME/.bashrc" || echo "$CONDA_ENV_ACTIVATE" >> "$HOME/.bashrc"

  # shellcheck disable=SC1091
  . /opt/conda/etc/profile.d/conda.sh
  conda_envs=$(conda env list)
  if ! grep -q rstudio$ <<< "$conda_envs"; then
    echo "no existing environment found"
    conda create --use-index-cache --clone root -n rstudio --copy -y \
    && chown -R "${USER}:${GROUP}" "/home/$USER/.conda/"
    chmod -R 775 "/home/$USER/.conda/envs/rstudio/bin" \
    && chmod -R 775 "/home/$USER/.conda/envs/rstudio/lib/R/bin"
  else
    echo "Conda Rstudio environment already exists"
  fi

}


function init_r() {

# set secure cookie key
set +x
echo -n "${SECURE_COOKIE_KEY}" > /var/lib/rstudio-server/secure-cookie-key
set -x
chmod 600 /var/lib/rstudio-server/secure-cookie-key

echo '.libPaths(c("~/R/library", paste0(R.home(), "/library"), .libPaths() ))' >> /usr/local/lib/R/etc/Rprofile.site \
    && echo "PATH=\"${PATH}\"" >> "$R_HOME/etc/Renviron" \
    && echo "AWS_DEFAULT_REGION=eu-west-1" >> "$R_HOME/etc/Renviron"
}




function start() {
RSTUDIO_ENV_PATH=$(conda info --env | grep -v \# | grep rstudio | tr -s " " | cut -f2 -d' ' | head -n1)

# shellcheck disable=SC1091
. /opt/conda/etc/profile.d/conda.sh

conda activate rstudio

export R_HOME=$CONDA_PREFIX/lib/R
# Update Renviron because we're not under an activated conda environment ($R_HOME is different)

[[ ! -f $R_HOME/etc/Renviron ]] \
  && touch "$R_HOME/etc/Renviron" \
  && chown "$USER" "$R_HOME/etc/Renviron"

# rstudio 1.2 uses `bash -l` instead of `bash` so we need to
# link the conda activate stuff into bash_profile
if [ ! -f ~/.bash_profile ]; then
  ln -s ~/.bashrc ~/.bash_profile
fi

grep -q -F "PATH" "$R_HOME/etc/Renviron" \
  && sed -i "s|PATH=.*|PATH=\"${PATH}\"|" "$R_HOME/etc/Renviron" \
  || echo "PATH=\"${PATH}\"" >> "$R_HOME/etc/Renviron"

grep -q -F "AWS_DEFAULT_REGION" "$R_HOME/etc/Renviron" \
  && sed -i "s|AWS_DEFAULT_REGION=.*|AWS_DEFAULT_REGION=eu-west-1|" "$R_HOME/etc/Renviron" \
  || echo "AWS_DEFAULT_REGION=eu-west-1" >> "$R_HOME/etc/Renviron"

# conda activate should be doing this but it doesn't 😭
grep -q -F "PKG_CONFIG_PATH" "$R_HOME/etc/Renviron" \
  && sed -i "s|PKG_CONFIG_PATH=.*|PKG_CONFIG_PATH=\"${CONDA_PREFIX}/lib/pkgconfig\"|" "$R_HOME/etc/Renviron" \
  || echo "PKG_CONFIG_PATH=\"${CONDA_PREFIX}/lib/pkgconfig\"" >> "$R_HOME/etc/Renviron"

sudo -i -u "${USER}" /usr/lib/rstudio-server/bin/rserver \
  --server-daemonize=0 \
  --rsession-ld-library-path="/usr/lib/rstudio-server:/opt/conda/lib:$RSTUDIO_ENV_PATH/lib" \
  --rsession-which-r="$RSTUDIO_ENV_PATH/bin/R"
}



function main() {
  init_user
  init_conda
  init_r
  start
}

case "$1" in
  init) init_user; init_conda; init_r ;;
  start) init_user; start ;;
  init_user)  init_user ;;
  init_conda)  init_conda ;;
  init_r)  init_r ;;
  *)         main ;; # for backwards compatibility
esac
