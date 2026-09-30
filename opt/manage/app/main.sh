#!/usr/bin/env bash
# shellcheck shell=bash

manage_loader_spin_step() {
  local label="$1"
  local -a frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
  if [[ -t 1 ]]; then
    local i
    for (( i=0; i<6; i++ )); do
      local f="${frames[i % ${#frames[@]}]}"
      printf "\r  \033[1;33m%s\033[0m \033[1;37m%-28s\033[0m" "${f}" "${label}"
      sleep 0.04
    done
  fi
}

manage_loader_done_step() {
  local label="$1"
  local status="${2:-OK}"
  local mark="\033[1;32m✓\033[0m"
  local badge="\033[1;32mOK\033[0m"
  if [[ "${status}" != "OK" ]]; then
    mark="\033[1;31m✗\033[0m"
    badge="\033[1;31mFAIL\033[0m"
  fi
  if [[ -t 1 ]]; then
    printf "\r  %b \033[1;37m%-28s\033[0m [ %b ]\n" "${mark}" "${label}" "${badge}"
  fi
}

main() {
  need_root
  local action="${1:-}"

  local is_interactive_splash=0
  if [[ -t 1 && -z "${action}" ]]; then
    is_interactive_splash=1
    if [[ "${MANAGE_SPLASH_STARTED:-0}" != "1" ]]; then
      clear 2>/dev/null || true
      printf '\033[1;36m╭────────────────────────────────────────────────────────────╮\033[0m\n'
      printf '\033[1;36m│\033[0m  \033[1m\033[1;37mMembuka Panel\033[0m                                             \033[1;36m│\033[0m\n'
      printf '\033[1;36m╰────────────────────────────────────────────────────────────╯\033[0m\n\n'
    fi

    # 1. Modules
    manage_loader_spin_step "Memuat Modules ...."
    manage_loader_done_step "Memuat Modules ...." "OK"

    # 2. Service
    manage_loader_spin_step "Memuat Service ...."
  fi

  if ! manage_license_guard_preflight "${action}"; then
    if [[ "${is_interactive_splash}" == "1" ]]; then
      manage_loader_done_step "Memuat Service ...." "FAIL"
    fi
    return 1
  fi

  if [[ "${is_interactive_splash}" == "1" ]]; then
    manage_loader_done_step "Memuat Service ...." "OK"

    # 3. Database
    manage_loader_spin_step "Memuat Database ...."
  fi

  init_runtime_dirs
  ensure_account_quota_dirs
  if declare -F main_info_cache_refresh >/dev/null 2>&1; then
    main_info_cache_refresh 2>/dev/null || true
  fi

  if [[ "${is_interactive_splash}" == "1" ]]; then
    manage_loader_done_step "Memuat Database ...." "OK"
    printf '\n  \033[1;32m✓\033[0m \033[1m\033[1;32mSystem Siap\033[0m\n'
    sleep 0.35
  fi

  case "${action}" in
    __apply-ssh-network)
      if ! declare -F ssh_network_runtime_apply_now >/dev/null 2>&1; then
        warn "Hidden apply SSH Network tidak tersedia."
        return 1
      fi
      if ! ssh_network_runtime_apply_now; then
        warn "Apply runtime SSH Network gagal."
        return 1
      fi
      return 0
      ;;
    __sync-ssh-network-session-targets)
      if ! declare -F ssh_network_runtime_sync_session_targets_now >/dev/null 2>&1; then
        warn "Hidden sync target sesi SSH Network tidak tersedia."
        return 1
      fi
      if ! ssh_network_runtime_sync_session_targets_now; then
        warn "Sinkron target sesi SSH Network gagal."
        return 1
      fi
      return 0
      ;;
    __refresh-account-info)
      warn "Hidden bulk refresh ACCOUNT INFO dinonaktifkan."
      warn "Gunakan menu Domain Control > Refresh Account Info."
      return 1
      ;;
    __sync-domain-file)
      warn "Hidden sync compat domain dinonaktifkan."
      warn "Sinkronisasi compat domain hanya dikelola internal oleh flow Set Domain."
      return 1
      ;;
  esac

  if [[ -n "${action}" ]]; then
    manage_router_dispatch "${action}" "${@:2}"
    return $?
  fi

  main_menu
}
