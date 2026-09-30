#!/usr/bin/env bash
# shellcheck shell=bash

SSH_BANNER_FILE="${SSH_BANNER_FILE:-/etc/issue.net}"
SSH_MOTD_FILE="${SSH_MOTD_FILE:-/etc/motd}"
SSHD_BANNER_CONF_DIR="${SSHD_BANNER_CONF_DIR:-/etc/ssh/sshd_config.d}"
SSHD_BANNER_CONF="${SSHD_BANNER_CONF:-/etc/ssh/sshd_config.d/50-autoscript-banner.conf}"

banner_sync_ssh_config() {
  local banner_path="${1:-${SSH_BANNER_FILE}}"
  
  # 1. Pastikan permission /etc/issue.net dapat dibaca oleh semua service (sshd & dropbear)
  if [[ -f "${banner_path}" ]]; then
    chmod 644 "${banner_path}" 2>/dev/null || true
    chown root:root "${banner_path}" 2>/dev/null || true
  fi

  # 2. Sync OpenSSH Config
  if [[ -d "${SSHD_BANNER_CONF_DIR}" ]]; then
    printf 'Banner %s\n' "${banner_path}" > "${SSHD_BANNER_CONF}" 2>/dev/null || true
    chmod 644 "${SSHD_BANNER_CONF}" 2>/dev/null || true
  fi
  if [[ -f /etc/ssh/sshd_config ]]; then
    # Comment out any 'Banner none'
    sed -i -E 's|^[[:space:]]*Banner[[:space:]]+none|#Banner none|g' /etc/ssh/sshd_config 2>/dev/null || true
    if ! grep -q -E "^[[:space:]]*Banner[[:space:]]+" /etc/ssh/sshd_config 2>/dev/null; then
      printf '\nBanner %s\n' "${banner_path}" >> /etc/ssh/sshd_config 2>/dev/null || true
    else
      sed -i -E "s|^[[:space:]]*Banner[[:space:]]+.*|Banner ${banner_path}|g" /etc/ssh/sshd_config 2>/dev/null || true
    fi
  fi

  # 3. Sync Dropbear systemd service file (ensure -b flag exists)
  local dropbear_svc_file="/etc/systemd/system/sshws-dropbear.service"
  if [[ -f "${dropbear_svc_file}" ]]; then
    if ! grep -q -- "-b " "${dropbear_svc_file}" 2>/dev/null; then
      sed -i -E "s|(/usr/sbin/dropbear[[:space:]]+)|\1-b ${banner_path} |g" "${dropbear_svc_file}" 2>/dev/null || true
      systemctl daemon-reload >/dev/null 2>&1 || true
    fi
  fi

  # 4. Sync Dropbear default configuration if exists
  if [[ -f /etc/default/dropbear ]]; then
    if grep -q "^DROPBEAR_BANNER=" /etc/default/dropbear 2>/dev/null; then
      sed -i "s|^DROPBEAR_BANNER=.*|DROPBEAR_BANNER=\"${banner_path}\"|g" /etc/default/dropbear 2>/dev/null || true
    else
      printf '\nDROPBEAR_BANNER="%s"\n' "${banner_path}" >> /etc/default/dropbear 2>/dev/null || true
    fi
  fi

  # 5. Restart / Reload OpenSSH & Dropbear Services
  if systemctl is-active --quiet ssh 2>/dev/null; then
    systemctl restart ssh >/dev/null 2>&1 || systemctl reload ssh >/dev/null 2>&1 || true
  elif systemctl is-active --quiet sshd 2>/dev/null; then
    systemctl restart sshd >/dev/null 2>&1 || systemctl reload sshd >/dev/null 2>&1 || true
  fi

  if systemctl is-active --quiet sshws-dropbear 2>/dev/null; then
    systemctl restart sshws-dropbear >/dev/null 2>&1 || true
  fi
}

banner_view_current() {
  title
  echo "13) Tools > Banner > View Current Banner"
  hr
  echo "--- [1] SSH PRE-LOGIN BANNER (${SSH_BANNER_FILE}) ---"
  if [[ -f "${SSH_BANNER_FILE}" && -s "${SSH_BANNER_FILE}" ]]; then
    cat "${SSH_BANNER_FILE}"
  else
    echo "(Kosong / Belum diset)"
  fi
  echo
  hr
  echo "--- [2] LOGIN TERMINAL MOTD (${SSH_MOTD_FILE}) ---"
  if [[ -f "${SSH_MOTD_FILE}" && -s "${SSH_MOTD_FILE}" ]]; then
    cat "${SSH_MOTD_FILE}"
  else
    echo "(Kosong / Belum diset)"
  fi
  hr
  pause
}

banner_is_trial_license() {
  if [[ "${MAIN_INFO_CACHE_IS_TRIAL:-0}" == "1" || "${MAIN_INFO_CACHE_LICENSE_TYPE_NAME:-}" == "Trial" ]]; then
    return 0
  fi
  if [[ -f "/var/lib/autoscript-license/cache.json" ]]; then
    if grep -iq '"is_trial":\s*true\|"license_type":\s*"trial"' /var/lib/autoscript-license/cache.json 2>/dev/null; then
      return 0
    fi
  fi
  return 1
}

banner_apply_watermark_if_trial() {
  local content="$1"
  if ! banner_is_trial_license; then
    printf '%s\n' "${content}"
    return 0
  fi

  if [[ "${content}" =~ "ArjunCloud" || "${content}" =~ "ArjunaCloud" || "${content}" =~ "AutoScript By ArjunCloud" ]]; then
    printf '%s\n' "${content}"
    return 0
  fi

  if [[ "${content}" =~ "<font" || "${content}" =~ "<br>" || "${content}" =~ "<b>" ]]; then
    printf '%s<br><font color="#00ff00"><b>================================================</b></font><br><font color="#ffff00"><b>           AutoScript By ArjunCloud             </b></font><br><font color="#00ff00"><b>================================================</b></font>\n' "${content}"
  else
    printf '%s\n\n================================================\n           AutoScript By ArjunCloud\n================================================\n' "${content}"
  fi
}

banner_template_ssh_html() {
  local is_trial="0"
  if banner_is_trial_license; then
    is_trial="1"
  fi

  cat <<EOF
<font color="#00ff00"><b>================================================</b></font><br>
<font color="#00ffff"><b>           PREMIUM SSH & VPN SERVER             </b></font><br>
<font color="#00ff00"><b>================================================</b></font><br>
<font color="#ffcc00"><b>  TERMS OF SERVICE / ATURAN PENGGUNAAN:        </b></font><br>
<font color="#ffffff">  - DILARANG DDOS / HACKING / SCANNING          </font><br>
<font color="#ffffff">  - DILARANG CARDING / SPAMMING / FRAUD         </font><br>
<font color="#ffffff">  - DILARANG TORRENT / P2P DOWNLOAD             </font><br>
<font color="#ffffff">  - DILARANG MULTI-LOGIN MELEBIHI BATAS MAX IP  </font><br>
<font color="#ff0000"><b>  MELANGGAR RULES = AUTO BAN / TERMINATION!     </b></font><br>
EOF
  if [[ "${is_trial}" == "1" ]]; then
    cat <<EOF
<font color="#00ff00"><b>================================================</b></font><br>
<font color="#ffff00"><b>           AutoScript By ArjunCloud             </b></font><br>
<font color="#00ff00"><b>================================================</b></font><br>
EOF
  else
    cat <<EOF
<font color="#00ff00"><b>================================================</b></font><br>
EOF
  fi
}

banner_template_motd_text() {
  local hostname_val
  hostname_val="$(hostname 2>/dev/null || echo "vps")"
  cat <<EOF
============================================================
  Selamat Datang di VPS Server: ${hostname_val}
============================================================
  Gunakan perintah 'manage' untuk membuka Control Panel VPS.
  Jaga kerahasiaan kredensial dan patuhi aturan server.
============================================================
              Copyright 2026 ArjunCloud & Teams
============================================================
EOF
}

banner_set_ssh_template() {
  title
  echo "13) Tools > Banner > Apply Template SSH (HTML)"
  hr
  echo "Preview Template:"
  banner_template_ssh_html
  hr
  if confirm_yn_or_back "Pasang template banner SSH di atas ke ${SSH_BANNER_FILE}?"; then
    banner_template_ssh_html > "${SSH_BANNER_FILE}"
    chmod 644 "${SSH_BANNER_FILE}" 2>/dev/null || true
    (
      banner_sync_ssh_config "${SSH_BANNER_FILE}"
    ) &
    local sync_pid=$!
    if declare -F ui_spinner_wait >/dev/null 2>&1; then
      ui_spinner_wait "${sync_pid}" "Sinkronisasi Banner & Restart Service"
    else
      wait "${sync_pid}" 2>/dev/null || true
    fi
    echo
    log "Banner SSH (${SSH_BANNER_FILE}) berhasil diperbarui dengan template default."
  else
    warn "Pemasangan template banner SSH dibatalkan."
  fi
  pause
}

banner_set_ssh_manual() {
  title
  echo "13) Tools > Banner > Input Manual Banner SSH"
  hr
  echo "Masukkan teks atau kode HTML untuk Banner SSH (${SSH_BANNER_FILE})."
  echo "Akhiri input dengan mengetik 'EOF' pada baris baru (atau ketik 'batal' untuk keluar):"
  hr
  local line buffer=""
  while IFS= read -r line || [[ -n "${line}" ]]; do
    local clean_line="${line%$'\r'}"
    clean_line="${clean_line#"${clean_line%%[![:space:]]*}"}"
    clean_line="${clean_line%"${clean_line##*[![:space:]]}"}"
    if [[ "${clean_line^^}" == "EOF" ]]; then
      break
    fi
    if [[ "${clean_line,,}" == "batal" || "${clean_line,,}" == "cancel" ]]; then
      warn "Input manual dibatalkan."
      pause
      return 0
    fi
    buffer+="${line%$'\r'}"$'\n'
  done
  if [[ -z "${buffer// /}" ]]; then
    warn "Teks banner kosong. Perubahan dibatalkan."
    pause
    return 0
  fi
  local final_content
  final_content="$(banner_apply_watermark_if_trial "${buffer}")"
  local byte_len="${#final_content}"
  if (( byte_len > 1950 )); then
    warn "Perhatian: Ukuran banner (${byte_len} bytes) mendekati batas maksimal Dropbear (2048 bytes)."
    warn "Gunakan format HTML yang ringkas agar koneksi SSH WebSocket stabil."
  fi
  printf '%s\n' "${final_content}" > "${SSH_BANNER_FILE}"
  chmod 644 "${SSH_BANNER_FILE}" 2>/dev/null || true
  (
    banner_sync_ssh_config "${SSH_BANNER_FILE}"
  ) &
  local sync_pid=$!
  if declare -F ui_spinner_wait >/dev/null 2>&1; then
    ui_spinner_wait "${sync_pid}" "Sinkronisasi Banner & Restart Service"
  else
    wait "${sync_pid}" 2>/dev/null || true
  fi
  echo
  log "Banner SSH (${SSH_BANNER_FILE}) berhasil disimpan dan service telah disinkronkan."
  pause
}

banner_set_ssh_url() {
  title
  echo "13) Tools > Banner > Download Banner SSH dari URL"
  hr
  local url=""
  if ! read -r -p "Masukkan URL Raw Banner (contoh: https://raw.github.../banner.txt) (atau kembali): " url; then
    echo
    return 0
  fi
  if is_back_choice "${url}" || [[ -z "${url}" ]]; then
    return 0
  fi
  if [[ ! "${url}" =~ ^https?:// ]]; then
    warn "URL tidak valid. Harus diawali http:// atau https://"
    pause
    return 0
  fi

  local tmp_file
  tmp_file="$(mktemp /tmp/banner.XXXXXX 2>/dev/null || echo "/tmp/banner.tmp")"
  if curl -fsSL --connect-timeout 10 --max-time 20 "${url}" -o "${tmp_file}" 2>/dev/null || wget -q -T 10 -O "${tmp_file}" "${url}" 2>/dev/null; then
    if [[ -s "${tmp_file}" ]]; then
      local raw_content final_content
      raw_content="$(cat "${tmp_file}")"
      final_content="$(banner_apply_watermark_if_trial "${raw_content}")"
      printf '%s\n' "${final_content}" > "${SSH_BANNER_FILE}"
      rm -f "${tmp_file}" 2>/dev/null || true
      chmod 644 "${SSH_BANNER_FILE}" 2>/dev/null || true
      (
        banner_sync_ssh_config "${SSH_BANNER_FILE}"
      ) &
      local sync_pid=$!
      if declare -F ui_spinner_wait >/dev/null 2>&1; then
        ui_spinner_wait "${sync_pid}" "Sinkronisasi Banner & Restart Service"
      else
        wait "${sync_pid}" 2>/dev/null || true
      fi
      echo
      log "Banner SSH berhasil diunduh dan disimpan ke ${SSH_BANNER_FILE}."
    else
      rm -f "${tmp_file}" 2>/dev/null || true
      warn "File hasil unduhan kosong."
    fi
  else
    rm -f "${tmp_file}" 2>/dev/null || true
    warn "Gagal mengunduh banner dari URL: ${url}"
  fi
  pause
}

banner_set_motd_manual() {
  title
  echo "13) Tools > Banner > Input Manual Post-Login MOTD"
  hr
  echo "Masukkan teks untuk Banner Post-Login Terminal (${SSH_MOTD_FILE})."
  echo "Akhiri input dengan mengetik 'EOF' pada baris baru (atau ketik 'batal' untuk keluar):"
  hr
  local line buffer=""
  while IFS= read -r line || [[ -n "${line}" ]]; do
    local clean_line="${line%$'\r'}"
    clean_line="${clean_line#"${clean_line%%[![:space:]]*}"}"
    clean_line="${clean_line%"${clean_line##*[![:space:]]}"}"
    if [[ "${clean_line^^}" == "EOF" ]]; then
      break
    fi
    if [[ "${clean_line,,}" == "batal" || "${clean_line,,}" == "cancel" ]]; then
      warn "Input manual MOTD dibatalkan."
      pause
      return 0
    fi
    buffer+="${line%$'\r'}"$'\n'
  done
  if [[ -z "${buffer// /}" ]]; then
    warn "Teks MOTD kosong. Perubahan dibatalkan."
    pause
    return 0
  fi
  printf '%s' "${buffer}" > "${SSH_MOTD_FILE}"
  chmod 644 "${SSH_MOTD_FILE}" 2>/dev/null || true
  log "Banner Post-Login (${SSH_MOTD_FILE}) berhasil disimpan."
  pause
}

banner_set_motd_template() {
  title
  echo "13) Tools > Banner > Apply Template Post-Login MOTD"
  hr
  echo "Preview Template:"
  banner_template_motd_text
  hr
  if confirm_yn_or_back "Pasang template MOTD di atas ke ${SSH_MOTD_FILE}?"; then
    banner_template_motd_text > "${SSH_MOTD_FILE}"
    chmod 644 "${SSH_MOTD_FILE}" 2>/dev/null || true
    log "Banner Post-Login (${SSH_MOTD_FILE}) berhasil diperbarui dengan template default."
  else
    warn "Pemasangan template MOTD dibatalkan."
  fi
  pause
}

banner_reset_all() {
  title
  echo "13) Tools > Banner > Reset / Hapus Banner"
  hr
  if confirm_yn_or_back "Kosongkan semua banner SSH (${SSH_BANNER_FILE}) dan MOTD (${SSH_MOTD_FILE})?"; then
    : > "${SSH_BANNER_FILE}" 2>/dev/null || true
    : > "${SSH_MOTD_FILE}" 2>/dev/null || true
    chmod 644 "${SSH_BANNER_FILE}" "${SSH_MOTD_FILE}" 2>/dev/null || true
    (
      banner_sync_ssh_config "${SSH_BANNER_FILE}"
    ) &
    local sync_pid=$!
    if declare -F ui_spinner_wait >/dev/null 2>&1; then
      ui_spinner_wait "${sync_pid}" "Sinkronisasi Reset Banner"
    else
      wait "${sync_pid}" 2>/dev/null || true
    fi
    echo
    log "Banner SSH dan MOTD berhasil dikosongkan."
  else
    warn "Reset banner dibatalkan."
  fi
  pause
}

tools_banner_menu() {
  local -a items=(
    "1|Lihat Banner Saat Ini"
    "2|Set Banner SSH - Input Manual"
    "3|Set Banner SSH - Template (HTML)"
    "4|Set Banner SSH - Unduh dari URL"
    "5|Set Banner Post-Login - Input Manual"
    "6|Set Banner Post-Login - Template"
    "7|Reset / Kosongkan Semua Banner"
    "0|Back"
  )
  while true; do
    ui_menu_screen_begin "13) Tools > Banner SSH & Login"
    ui_menu_render_options items 76
    hr
    if ! read -r -p "Pilih: " c; then
      echo
      break
    fi
    case "${c}" in
      1) banner_view_current ;;
      2) banner_set_ssh_manual ;;
      3) banner_set_ssh_template ;;
      4) banner_set_ssh_url ;;
      5) banner_set_motd_manual ;;
      6) banner_set_motd_template ;;
      7) banner_reset_all ;;
      0|kembali|k|back|b) break ;;
      *) warn "Pilihan tidak valid" ; sleep 1 ;;
    esac
  done
}
