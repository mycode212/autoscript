#!/usr/bin/env bash
# ============================================================
# update.sh — Updater Otomatis Script VPS
# Repo: https://github.com/mycode212/autoscript
# ============================================================
set -euo pipefail

SAFE_PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
PATH="${SAFE_PATH}"
export PATH

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo -e "\033[0;31m[ERROR] Jalankan updater ini sebagai root.\033[0m" >&2
  exit 1
fi

AUTOSCRIPT_VERSION_LOCAL_FILE="/etc/autoscript/version"
AUTOSCRIPT_VERSION_FALLBACK_FILE="/opt/autoscript/version"
AUTOSCRIPT_VERSION_REMOTE_URL="https://raw.githubusercontent.com/mycode212/autoscript/main/version"
AUTOSCRIPT_REPO_URL="https://github.com/mycode212/autoscript.git"
AUTOSCRIPT_REPO_DIR="/opt/autoscript"
AUTOSCRIPT_DEFAULT_VERSION="1.0.0"

UI_BORDER="\033[1;36m"
UI_ACCENT="\033[1;33m"
UI_WARN="\033[1;33m"
UI_SUCCESS="\033[1;32m"
UI_PRIMARY="\033[1;34m"
UI_WHITE="\033[1;37m"
UI_MUTED="\033[0;37m"
UI_ERR="\033[0;31m"
UI_RESET="\033[0m"

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
  local remote_ver="" now
  now="$(date +%s 2>/dev/null || echo 0)"
  if command -v curl >/dev/null 2>&1; then
    remote_ver="$(curl -fsSL --connect-timeout 4 --max-time 8 -H "Cache-Control: no-cache" -H "Pragma: no-cache" "${AUTOSCRIPT_VERSION_REMOTE_URL}?t=${now}" 2>/dev/null | head -n1 | tr -d ' \r\n' || true)"
  elif command -v wget >/dev/null 2>&1; then
    remote_ver="$(wget -qO- --timeout=8 --no-cache "${AUTOSCRIPT_VERSION_REMOTE_URL}?t=${now}" 2>/dev/null | head -n1 | tr -d ' \r\n' || true)"
  fi
  if [[ -z "${remote_ver}" || ! "${remote_ver}" =~ ^[0-9]+(\.[0-9]+)* ]]; then
    remote_ver="-"
  fi
  printf '%s\n' "${remote_ver}"
}

autoscript_version_compare() {
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

clear || true
echo -e "${UI_BORDER}╭────────────────────────────────────────────────────────────╮${UI_RESET}"
echo -e "${UI_BORDER}│               AUTOSCRIPT XRAY & SSH UPDATER                │${UI_RESET}"
echo -e "${UI_BORDER}╰────────────────────────────────────────────────────────────╯${UI_RESET}\n"

cur_ver="$(autoscript_version_current_get)"
rem_ver="$(autoscript_version_remote_get)"

echo -e "  ${UI_ACCENT}Versi Terpasang :${UI_RESET} ${UI_WHITE}v${cur_ver}${UI_RESET}"
echo -e "  ${UI_ACCENT}Versi Terbaru   :${UI_RESET} ${UI_WARN}v${rem_ver}${UI_RESET}\n"

if [[ "${rem_ver}" != "-" ]]; then
  if ! autoscript_version_compare "${cur_ver}" "${rem_ver}"; then
    if [[ "${1:-}" != "--force" && "${1:-}" != "-f" ]]; then
      echo -e "  ${UI_SUCCESS}[✓] Versi Anda Sudah Versi Terakhir (v${cur_ver})${UI_RESET}"
      echo -e "  Tidak ada pembaruan yang diperlukan.\n"
      echo -e "  ${UI_MUTED}Gunakan perintah 'update --force' jika ingin me-reinstall ulang file script.${UI_RESET}\n"
      exit 0
    else
      echo -e "  ${UI_WARN}[!] Memaksa reinstall file script (--force)...${UI_RESET}\n"
    fi
  fi
fi

echo -e "${UI_PRIMARY}[1/5] Mempersiapkan backup konfigurasi...${UI_RESET}"
mkdir -p /etc/autoscript
backup_tmp="/var/backups/autoscript_update_$(date +%Y%m%d_%H%M%S)"
mkdir -p "${backup_tmp}"
if [[ -d "/opt/manage" ]]; then
  cp -a /opt/manage "${backup_tmp}/manage_backup" 2>/dev/null || true
fi

echo -e "${UI_PRIMARY}[2/5] Mengunduh script terbaru dari repository...${UI_RESET}"
if [[ -d "${AUTOSCRIPT_REPO_DIR}/.git" ]]; then
  echo -e "  -> Melakukan git pull..."
  if ! git -C "${AUTOSCRIPT_REPO_DIR}" pull origin main >/dev/null 2>&1; then
    echo -e "${UI_WARN}  [!] Git pull gagal, melakukan clone ulang...${UI_RESET}"
    rm -rf "${AUTOSCRIPT_REPO_DIR}.bak" 2>/dev/null || true
    mv "${AUTOSCRIPT_REPO_DIR}" "${AUTOSCRIPT_REPO_DIR}.bak" 2>/dev/null || true
    git clone --depth=1 "${AUTOSCRIPT_REPO_URL}" "${AUTOSCRIPT_REPO_DIR}" 2>/dev/null || true
  fi
else
  echo -e "  -> Mengkloning repository ke ${AUTOSCRIPT_REPO_DIR}..."
  mkdir -p "$(dirname "${AUTOSCRIPT_REPO_DIR}")"
  rm -rf "${AUTOSCRIPT_REPO_DIR}" 2>/dev/null || true
  git clone --depth=1 "${AUTOSCRIPT_REPO_URL}" "${AUTOSCRIPT_REPO_DIR}" 2>/dev/null || true
fi

if [[ ! -f "${AUTOSCRIPT_REPO_DIR}/manage.sh" ]]; then
  echo -e "${UI_ERR}[✗] Gagal mengunduh file script! Mengembalikan backup...${UI_RESET}"
  if [[ -d "${backup_tmp}/manage_backup" ]]; then
    cp -a "${backup_tmp}/manage_backup/." /opt/manage/ 2>/dev/null || true
  fi
  exit 1
fi

echo -e "${UI_PRIMARY}[3/5] Memperbarui modul management & binary CLI...${UI_RESET}"
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

echo -e "${UI_PRIMARY}[4/5] Memeriksa dependensi sistem...${UI_RESET}"
needed_pkgs=()
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

echo -e "${UI_PRIMARY}[5/5] Menyimpan versi dan reload service...${UI_RESET}"
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

final_ver="$(autoscript_version_current_get)"
echo -e "\n${UI_SUCCESS}╭────────────────────────────────────────────────────────────╮${UI_RESET}"
echo -e "${UI_SUCCESS}│             UPDATE SCRIPT BERHASIL SELESAI!                │${UI_RESET}"
echo -e "${UI_SUCCESS}├────────────────────────────────────────────────────────────┤${UI_RESET}"
printf "${UI_SUCCESS}│${UI_RESET}  Versi Lama   : ${UI_WHITE}%-43s${UI_RESET}${UI_SUCCESS}│${UI_RESET}\n" "v${cur_ver}"
printf "${UI_SUCCESS}│${UI_RESET}  Versi Baru   : ${UI_SUCCESS}%-43s${UI_RESET}${UI_SUCCESS}│${UI_RESET}\n" "v${final_ver}"
printf "${UI_SUCCESS}│${UI_RESET}  Perintah CLI : ${UI_WARN}%-43s${UI_RESET}${UI_SUCCESS}│${UI_RESET}\n" "manage / update"
echo -e "${UI_SUCCESS}╰────────────────────────────────────────────────────────────╯${UI_RESET}\n"

echo -e "Ketik ${UI_WARN}manage${UI_RESET} untuk membuka menu utama kembali.\n"
