#!/usr/bin/env bash
set -ex

USER="rstudio"
USER_UID="1000"
USER_HOME=$(getent passwd "${USER_UID:?}" | cut -d: -f6)

function cleanup() {
  if [[ -d "${USER_HOME}/.conda/envs/rstudio" ]];then
    rm -rf "${USER_HOME}/.conda/envs/rstudio"
  fi
}

trap cleanup ERR
source functions.sh

function init_user() {
  usermod -a -G "staff,users" "${USER}"
}

function init_conda() {
  ## if user has ~/.bashrc make sure conda is added to that
  CONDA_SNIPPET='[[ -f /opt/conda/etc/profile.d/conda.sh ]] && . /opt/conda/etc/profile.d/conda.sh'
  CONDA_ENV_ACTIVATE='[[ -v RSTUDIO ]] && conda activate rstudio'

  append_to_file "${CONDA_SNIPPET}" "${USER_HOME}/.bashrc"
  append_to_file  "${CONDA_ENV_ACTIVATE}" >> "${HOME}/.bashrc"

  # shellcheck disable=SC1091
  source /opt/conda/etc/profile.d/conda.sh

  if [[ $(conda env list | grep 'rstudio') != 0 ]]; then
    echo "no existing Conda environment found, creating..."
    fix_or_initialize_conda_home "${USER_HOME}"
    conda create --use-index-cache --clone root -n rstudio --copy -y
  else
    echo "Conda Rstudio environment already exists"
  fi
}

function init_r() {
  write_file "${SECURE_COOKIE_KEY:?}" '/var/lib/rstudio-server/secure-cookie-key'
  chmod 600 /var/lib/rstudio-server/secure-cookie-key

  append_to_file '.libPaths(c("~/R/library", paste0(R.home(), "/library"), .libPaths() ))' '/usr/local/lib/R/etc/Rprofile.site'
  append_to_file "PATH=\"${PATH}\"" "${R_HOME:?}/etc/Renviron"
  append_to_file 'AWS_DEFAULT_REGION=eu-west-1' "${R_HOME:?}/etc/Renviron"
}

function start() {
  local RSTUDIO_ENV_PATH
  local R_HOME

  # Update Renviron because we're not under an activated conda environment (${R_HOME:?} is different)
  RSTUDIO_ENV_PATH=$(conda info --env | grep -v \# | grep rstudio | tr -s " " | cut -f2 -d' ' | head -n1)
  R_HOME=${CONDA_PREFIX:?}/lib/R

  # shellcheck disable=SC1091
  source /opt/conda/etc/profile.d/conda.sh

  init_conda &&\
  conda activate rstudio

  if [[ ! -f ${R_HOME:?}/etc/Renviron ]];then
    touch "${R_HOME:?}/etc/Renviron"
    chown "${USER}" "${R_HOME:?}/etc/Renviron"
  fi

  # rstudio 1.2 uses `bash -l` instead of `bash` so we need to
  # link the conda activate script into bash_profile
  if [[ ! -f ~/.bash_profile ]]; then
    ln -s ~/.bashrc ~/.bash_profile
  fi

  if grep -F "PATH" "${R_HOME:?}/etc/Renviron";then
    sed -i "s|PATH=.*|PATH=\"${PATH}\"|" "${R_HOME:?}/etc/Renviron"
    append_to_file "PATH=\"${PATH}\"" "${R_HOME:?}/etc/Renviron"
  fi

  if grep -F "AWS_DEFAULT_REGION" "${R_HOME:?}/etc/Renviron";then
    sed -i "s|AWS_DEFAULT_REGION=.*|AWS_DEFAULT_REGION=eu-west-1|" "${R_HOME:?}/etc/Renviron"
    append_to_file "AWS_DEFAULT_REGION=eu-west-1" "${R_HOME:?}/etc/Renviron"
  fi

  # conda activate should be doing this but it doesn't
  # TODO check this is still the case
  if grep -F "PKG_CONFIG_PATH" "${R_HOME:?}/etc/Renviron";then
    sed -i "s|PKG_CONFIG_PATH=.*|PKG_CONFIG_PATH=\"${CONDA_PREFIX:?}/lib/pkgconfig\"|" "${R_HOME:?}/etc/Renviron" \
    append_to_file "PKG_CONFIG_PATH=\"${CONDA_PREFIX:?}/lib/pkgconfig\"" "${R_HOME:?}/etc/Renviron"
  fi

  # TODO use native S6 overlay to drop permissions instead of sudo
  # https://github.com/just-containers/s6-overlay#dropping-privileges
  sudo -i -u "${USER}" /usr/lib/rstudio-server/bin/rserver \
    --server-daemonize=0 \
    --rsession-ld-library-path="/usr/lib/rstudio-server:/opt/conda/lib:$RSTUDIO_ENV_PATH/lib" \
    --rsession-which-r="$RSTUDIO_ENV_PATH/bin/R"
}

function main() {
  init_user
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
