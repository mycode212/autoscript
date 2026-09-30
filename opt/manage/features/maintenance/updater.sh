#!/usr/bin/env bash
# shellcheck shell=bash
# Module: Updater & Versioning System for Autoscript
# -------------------------------------------------------------

AUTOSCRIPT_VERSION_LOCAL_FILE="${AUTOSCRIPT_VERSION_LOCAL_FILE:-/etc/autoscript/version}"
AUTOSCRIPT_VERSION_FALLBACK_FILE="${AUTOSCRIPT_VERSION_FALLBACK_FILE:-/opt/autoscript/version}"
AUTOSCRIPT_VERSION_REMOTE_URL="${AUTOSCRIPT_VERSION_REMOTE_URL:-https://raw.githubusercontent.com/mycode212/autoscript/main/version}"
AUTOSCRIPT_REPO_URL="${AUTOSCRIPT_REPO_URL:-https://github.com/mycode212/autoscript.git}"
AUTOSCRIPT_REPO_DIR="${AUTOSCRIPT_REPO_DIR:-/opt/autoscript}"
AUTOSCRIPT_DEFAULT_VERSION="1.0.0"

autoscript_version_current_get() {
  local ver=""
  if [[ -f "${AUTOSCRIPT_VERSION_LOCAL_FILE}" ]]; then
    ver="$(head -n1 "${AUTOSCRIPT_VERSION_LOCAL_FILE}" 2>/dev/null | tr -d ' \r\n' || true)"
  fi
  if [[ -z "${ver}" && -f "${AUTOSCRIPT_VERSION_FALLBACK_FILE}" ]]; then
    ver="$(head -n1 "${AUTOSCRIPT_VERSION_FALLBACK_FILE}" 2>/dev/null | tr -d ' \r\n' || true)"
  fi
  if [[ -z "${ver}" ]]; then
    ver="${AUTOSCRIPT_DEFAULT_VERSION}"
  fi
  printf '%s\n' "${ver}"
}

autoscript_version_remote_get() {
  local remote_ver=""
  if command -v curl >/dev/null 2>&1; then
    remote_ver="$(curl -fsSL --connect-timeout 4 --max-time 8 "${AUTOSCRIPT_VERSION_REMOTE_URL}" 2>/dev/null | head -n1 | tr -d ' \r\n' || true)"
  elif command -v wget >/dev/null 2>&1; then
    remote_ver="$(wget -qO- --timeout=8 "${AUTOSCRIPT_VERSION_REMOTE_URL}" 2>/dev/null | head -n1 | tr -d ' \r\n' || true)"
  fi
  if [[ -z "${remote_ver}" || ! "${remote_ver}" =~ ^[0-9]+(\.[0-9]+)* ]]; then
    remote_ver="-"
  fi
  printf '%s\n' "${remote_ver}"
}

autoscript_version_compare() {
  # return 0 jika v1 < v2 (perlu update), 1 jika v1 == v2, 2 jika v1 > v2
  local v1="${1#v}"
  local v2="${2#v}"
  if [[ "${v1}" == "${v2}" ]]; then
    return 1
  fi
  local IFS=.
  local i ver1=(${v1}) ver2=(${v2})
  for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)); do
    ver1[i]=0
  done
  for ((i=${#ver2[@]}; i<${#ver1[@]}; i++)); do
    ver2[i]=0
  done
  for ((i=0; i<${#ver1[@]}; i++)); do
    if ((10#${ver1[i]} < 10#${ver2[i]})); then
      return 0
    elif ((10#${ver1[i]} > 10#${ver2[i]})); then
      return 2
    fi
  done
  return 1
}

autoscript_update_perform() {
  local cur_ver rem_ver
  cur_ver="$(autoscript_version_current_get)"
  rem_ver="$(autoscript_version_remote_get)"

  echo -e "\n${UI_BORDER}╭────────────────────[ SCRIPT UPDATER ]──────────────────────╮${UI_RESET}"
  printf "${UI_BORDER}│${UI_RESET}  ${UI_ACCENT}%-16s${UI_RESET} : ${UI_WHITE}%-39s${UI_RESET}${UI_BORDER}│${UI_RESET}\n" "Current Version" "v${cur_ver}"
  printf "${UI_BORDER}│${UI_RESET}  ${UI_ACCENT}%-16s${UI_RESET} : ${UI_WARN}%-39s${UI_RESET}${UI_BORDER}│${UI_RESET}\n" "Latest Version" "v${rem_ver}"
  echo -e "${UI_BORDER}╰────────────────────────────────────────────────────────────╯${UI_RESET}\n"

  if [[ "${rem_ver}" == "-" ]]; then
    echo -e "${UI_WARN}[!] Gagal memeriksa versi remote. Pastikan VPS terhubung ke internet.${UI_RESET}"
    if ! confirm_menu_apply_now "Tetap lanjutkan paksa update dari repository?"; then
      echo -e "${UI_MUTED}Update dibatalkan.${UI_RESET}"
      return 0
    fi
  elif [[ "${cur_ver}" == "${rem_ver}" ]]; then
    echo -e "${UI_SUCCESS}[✓] Script Anda sudah versi terbaru (v${cur_ver}).${UI_RESET}"
    if ! confirm_menu_apply_now "Apakah Anda ingin me-reinstall/memperbarui ulang file script?"; then
      echo -e "${UI_MUTED}Update dibatalkan.${UI_RESET}"
      return 0
    fi
  fi

  echo -e "${UI_PRIMARY}[1/6] Mempersiapkan direktori & backup konfigurasi...${UI_RESET}"
  mkdir -p /etc/autoscript
  local backup_tmp="/var/backups/autoscript_update_$(date +%Y%m%d_%H%M%S)"
  mkdir -p "${backup_tmp}"
  if [[ -d "/opt/manage" ]]; then
    cp -a /opt/manage "${backup_tmp}/manage_backup" 2>/dev/null || true
  fi

  echo -e "${UI_PRIMARY}[2/6] Mengunduh pembaruan dari repository...${UI_RESET}"
  if [[ -d "${AUTOSCRIPT_REPO_DIR}/.git" ]]; then
    echo -e "  -> Mengambil update via git pull..."
    if ! git -C "${AUTOSCRIPT_REPO_DIR}" pull origin main >/dev/null 2>&1; then
      echo -e "${UI_WARN}  [!] Git pull gagal, mencoba clone ulang...${UI_RESET}"
      rm -rf "${AUTOSCRIPT_REPO_DIR}.bak" 2>/dev/null || true
      mv "${AUTOSCRIPT_REPO_DIR}" "${AUTOSCRIPT_REPO_DIR}.bak" 2>/dev/null || true
      git clone --depth=1 "${AUTOSCRIPT_REPO_URL}" "${AUTOSCRIPT_REPO_DIR}" 2>/dev/null || true
    fi
  else
    echo -e "  -> Melakukan clone fresh repository ke ${AUTOSCRIPT_REPO_DIR}..."
    mkdir -p "$(dirname "${AUTOSCRIPT_REPO_DIR}")"
    rm -rf "${AUTOSCRIPT_REPO_DIR}" 2>/dev/null || true
    git clone --depth=1 "${AUTOSCRIPT_REPO_URL}" "${AUTOSCRIPT_REPO_DIR}" 2>/dev/null || true
  fi

  if [[ ! -f "${AUTOSCRIPT_REPO_DIR}/manage.sh" ]]; then
    echo -e "${UI_ERR}[✗] Gagal mengunduh script baru! Mengembalikan backup...${UI_RESET}"
    if [[ -d "${backup_tmp}/manage_backup" ]]; then
      cp -a "${backup_tmp}/manage_backup/." /opt/manage/ 2>/dev/null || true
    fi
    return 1
  fi

  echo -e "${UI_PRIMARY}[3/6] Memperbarui modul management & CLI...${UI_RESET}"
  if [[ -d "${AUTOSCRIPT_REPO_DIR}/opt/manage" ]]; then
    mkdir -p /opt/manage
    cp -a "${AUTOSCRIPT_REPO_DIR}/opt/manage/." /opt/manage/
    find /opt/manage -type d -exec chmod 755 {} + 2>/dev/null || true
    find /opt/manage -type f -name '*.sh' -exec chmod 644 {} + 2>/dev/null || true
  fi

  install -m 0755 "${AUTOSCRIPT_REPO_DIR}/manage.sh" /usr/local/bin/manage
  if [[ -f "${AUTOSCRIPT_REPO_DIR}/install-telegram-bot.sh" ]]; then
    install -m 0755 "${AUTOSCRIPT_REPO_DIR}/install-telegram-bot.sh" /usr/local/bin/install-telegram-bot
  fi
  if [[ -f "${AUTOSCRIPT_REPO_DIR}/update.sh" ]]; then
    install -m 0755 "${AUTOSCRIPT_REPO_DIR}/update.sh" /usr/local/bin/update
    install -m 0755 "${AUTOSCRIPT_REPO_DIR}/update.sh" /usr/local/bin/update-script 2>/dev/null || true
  fi

  echo -e "${UI_PRIMARY}[4/6] Memeriksa & menginstal requirements/dependensi baru...${UI_RESET}"
  local needed_pkgs=()
  for pkg in jq curl vnstat net-tools python3 git; do
    if ! command -v "${pkg}" >/dev/null 2>&1; then
      needed_pkgs+=("${pkg}")
    fi
  done
  if (( ${#needed_pkgs[@]} > 0 )); then
    echo -e "  -> Menginstal dependensi baru: ${needed_pkgs[*]} ..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq >/dev/null 2>&1 || true
    apt-get install -y -qq "${needed_pkgs[@]}" >/dev/null 2>&1 || true
  fi

  echo -e "${UI_PRIMARY}[5/6] Memperbarui versi lokal & status services...${UI_RESET}"
  if [[ -f "${AUTOSCRIPT_REPO_DIR}/version" ]]; then
    cp -f "${AUTOSCRIPT_REPO_DIR}/version" /etc/autoscript/version
    chmod 644 /etc/autoscript/version 2>/dev/null || true
  elif [[ "${rem_ver}" != "-" ]]; then
    echo "${rem_ver}" > /etc/autoscript/version
    chmod 644 /etc/autoscript/version 2>/dev/null || true
  fi
  if [[ -f "${AUTOSCRIPT_REPO_DIR}/changelog.txt" ]]; then
    cp -f "${AUTOSCRIPT_REPO_DIR}/changelog.txt" /etc/autoscript/changelog.txt
    chmod 644 /etc/autoscript/changelog.txt 2>/dev/null || true
  fi

  systemctl daemon-reload >/dev/null 2>&1 || true
  if svc_exists ssh-network-restore; then
    systemctl restart ssh-network-restore.service >/dev/null 2>&1 || true
  fi

  local final_ver
  final_ver="$(autoscript_version_current_get)"
  echo -e "\n${UI_SUCCESS}╭────────────────────────────────────────────────────────────╮${UI_RESET}"
  echo -e "${UI_SUCCESS}│             UPDATE SCRIPT BERHASIL SELESAI!                │${UI_RESET}"
  echo -e "${UI_SUCCESS}├────────────────────────────────────────────────────────────┤${UI_RESET}"
  printf "${UI_SUCCESS}│${UI_RESET}  Versi Lama   : ${UI_WHITE}%-43s${UI_RESET}${UI_SUCCESS}│${UI_RESET}\n" "v${cur_ver}"
  printf "${UI_SUCCESS}│${UI_RESET}  Versi Baru   : ${UI_SUCCESS}%-43s${UI_RESET}${UI_SUCCESS}│${UI_RESET}\n" "v${final_ver}"
  printf "${UI_SUCCESS}│${UI_RESET}  Perintah CLI : ${UI_WARN}%-43s${UI_RESET}${UI_SUCCESS}│${UI_RESET}\n" "manage / update"
  echo -e "${UI_SUCCESS}╰────────────────────────────────────────────────────────────╯${UI_RESET}\n"
  
  if declare -F main_info_cache_invalidate >/dev/null 2>&1; then
    main_info_cache_invalidate
  fi
  return 0
}

tools_updater_menu() {
  while true; do
    local cur_ver rem_ver status_label
    cur_ver="$(autoscript_version_current_get)"
    rem_ver="$(autoscript_version_remote_get)"

    if [[ "${rem_ver}" == "-" ]]; then
      status_label="${UI_WARN}Offline / Tidak dapat dicek${UI_RESET}"
    else
      autoscript_version_compare "${cur_ver}" "${rem_ver}"
      case $? in
        0) status_label="${UI_WARN}Pembaruan Tersedia (v${rem_ver})!${UI_RESET}" ;;
        1) status_label="${UI_SUCCESS}Versi Terbaru (Up to date)${UI_RESET}" ;;
        2) status_label="${UI_ACCENT}Versi Development (v${cur_ver})${UI_RESET}" ;;
      esac
    fi

    ui_menu_screen_begin "13) Tools -> Update Script"
    echo -e "${UI_BORDER}╭─────────────────────[ VERSION INFO ]───────────────────────╮${UI_RESET}"
    printf "${UI_BORDER}│${UI_RESET}  ${UI_ACCENT}%-16s${UI_RESET} : ${UI_WHITE}%-39s${UI_RESET}${UI_BORDER}│${UI_RESET}\n" "Current Version" "v${cur_ver}"
    printf "${UI_BORDER}│${UI_RESET}  ${UI_ACCENT}%-16s${UI_RESET} : ${UI_WHITE}%-39s${UI_RESET}${UI_BORDER}│${UI_RESET}\n" "Latest Version" "v${rem_ver}"
    printf "${UI_BORDER}│${UI_RESET}  ${UI_ACCENT}%-16s${UI_RESET} : %b${UI_BORDER}│${UI_RESET}\n" "Status" "${status_label}"
    echo -e "${UI_BORDER}╰────────────────────────────────────────────────────────────╯${UI_RESET}"

    local -a items=(
      "1|Periksa & Jalankan Update Script"
      "2|Paksa Reinstall File Script (Force Update)"
      "3|Lihat Changelog / Riwayat Pembaruan"
      "0|Back"
    )
    ui_menu_render_options items 76
    hr
    if ! read -r -p "Pilih: " c; then
      echo
      break
    fi
    case "${c}" in
      1) autoscript_update_perform ; wait_enter ;;
      2)
        if confirm_menu_apply_now "Paksa update/reinstall seluruh file script dari repositori?"; then
          autoscript_update_perform
        fi
        wait_enter
        ;;
      3)
        echo -e "\n${UI_ACCENT}--- Riwayat Pembaruan (Changelog) ---${UI_RESET}"
        if [[ -f "/etc/autoscript/changelog.txt" ]]; then
          cat "/etc/autoscript/changelog.txt"
        elif [[ -f "${AUTOSCRIPT_REPO_DIR}/changelog.txt" ]]; then
          cat "${AUTOSCRIPT_REPO_DIR}/changelog.txt"
        else
          curl -fsSL --connect-timeout 3 --max-time 6 "https://raw.githubusercontent.com/mycode212/autoscript/main/changelog.txt" 2>/dev/null || echo -e "${UI_MUTED}Changelog belum tersedia.${UI_RESET}"
        fi
        echo
        wait_enter
        ;;
      0|kembali|k|back|b) break ;;
      *) warn "Pilihan tidak valid" ; sleep 1 ;;
    esac
  done
}
