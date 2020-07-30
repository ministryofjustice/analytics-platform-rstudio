#!/usr/bin/env bash
set -ex

function append_to_file() {
  set -x
  local ENTRY=${1:?}
  local FILE=${2:?}

  if [[ $(grep "${ENTRY}" "${FILE}") -eq 0 ]];then
    echo "${ENTRY}" >> "${FILE}"
  fi

  set +x
}

function write_file() {
  set -x
  local ENTRY=${1:?}
  local FILE=${2:?}

  if [[ $(grep -F "${ENTRY}" "${FILE}") -eq 0 ]];then
    echo -n "${ENTRY}" > "${FILE}"
  fi

  set +x
}

function fix_or_initialize_conda_home() {
  local USER_HOME=${1:?}

  if [[ ! -d "${USER_HOME}/.conda" ]];then
    mkdir -p "${USER_HOME}/.conda"
    chown -R "${USER}:${GROUP}" "${USER_HOME}/.conda/"
    chmod -R 775 "${USER_HOME:?}/.conda/envs/rstudio/bin"
    chmod -R 775 "${USER_HOME:?}/.conda/envs/rstudio/lib/R/bin"
  fi
}
