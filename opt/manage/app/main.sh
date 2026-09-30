#!/usr/bin/env bash
# shellcheck shell=bash

manage_splash_loader() {
  [[ -t 1 ]] || return 0

  clear 2>/dev/null || true
  echo -e "${UI_BORDER}╭────────────────────────────────────────────────────────────╮${UI_RESET}"
  echo -e "${UI_BORDER}│${UI_RESET}  ${UI_BOLD}${UI_WHITE}Membuka Panel${UI_RESET}                                             ${UI_BORDER}│${UI_RESET}"
  echo -e "${UI_BORDER}╰────────────────────────────────────────────────────────────╯${UI_RESET}"
  echo ""

  printf "  ${UI_ACCENT}->${UI_RESET} ${UI_WHITE}%-28s${UI_RESET} " "Memuat Modules ...."
  sleep 0.25
  echo -e "[ ${UI_SUCCESS}OK${UI_RESET} ]"

  printf "  ${UI_ACCENT}->${UI_RESET} ${UI_WHITE}%-28s${UI_RESET} " "Memuat Service ...."
  sleep 0.25
  echo -e "[ ${UI_SUCCESS}OK${UI_RESET} ]"

  printf "  ${UI_ACCENT}->${UI_RESET} ${UI_WHITE}%-28s${UI_RESET} " "Memuat Database ...."
  sleep 0.25
  echo -e "[ ${UI_SUCCESS}OK${UI_RESET} ]"

  echo ""
  echo -e "  ${UI_SUCCESS}✓${UI_RESET} ${UI_BOLD}${UI_SUCCESS}System Siap${UI_RESET}"
  sleep 0.45
}

main() {
  need_root
  local action="${1:-}"
  if ! manage_license_guard_preflight "${action}"; then
    return 1
  fi
  init_runtime_dirs
  ensure_account_quota_dirs

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

  manage_splash_loader
  main_menu
}
