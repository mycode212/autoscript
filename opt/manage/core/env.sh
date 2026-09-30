#!/usr/bin/env bash
# shellcheck shell=bash

: "${MANAGE_MODULES_DIR:=/opt/manage}"
: "${MANAGE_MODULES_CORE_DIR:=${MANAGE_MODULES_DIR}/core}"
: "${MANAGE_MODULES_FEATURES_DIR:=${MANAGE_MODULES_DIR}/features}"
: "${MANAGE_MODULES_MENUS_DIR:=${MANAGE_MODULES_DIR}/menus}"
: "${MANAGE_MODULES_APP_DIR:=${MANAGE_MODULES_DIR}/app}"

if ! declare -F info >/dev/null 2>&1; then
  info() {
    if declare -F log >/dev/null 2>&1; then
      log "$@"
    else
      echo -e "\033[1;36m[manage]\033[0m $*"
    fi
  }
fi

if ! declare -F ok >/dev/null 2>&1; then
  ok() {
    if declare -F log >/dev/null 2>&1; then
      log "$@"
    else
      echo -e "\033[1;32m[manage][OK]\033[0m $*"
    fi
  }
fi
