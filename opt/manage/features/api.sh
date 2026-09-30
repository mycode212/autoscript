#!/usr/bin/env bash
# shellcheck shell=bash
# Non-interactive API endpoint for Master Orchestrator / Remote Web Panels

api_response_json() {
  local success="${1:-false}"
  local message="${2:-}"
  local data="${3:-{}}"
  
  python3 -c '
import json, sys
success = sys.argv[1].lower() in ("true", "1")
message = sys.argv[2]
data_raw = sys.argv[3]
try:
    data = json.loads(data_raw)
except Exception:
    try:
        data = json.loads(data_raw.replace("\\\"", "\""))
    except Exception:
        data = {"raw": data_raw}

print(json.dumps({
    "success": success,
    "message": message,
    "data": data
}, ensure_ascii=False))
' "${success}" "${message}" "${data}"
}

api_dispatch() {
  local sub="${1:-}"
  shift || true

  case "${sub}" in
    user-create|create-user)
      api_user_create "$@"
      ;;
    user-delete|delete-user)
      api_user_delete "$@"
      ;;
    user-renew|renew-user)
      api_user_renew "$@"
      ;;
    user-status|status-user)
      api_user_status "$@"
      ;;
    server-health|health)
      api_server_health "$@"
      ;;
    *)
      api_response_json false "Endpoint API '${sub}' tidak ditemukan. Tersedia: user-create, user-delete, user-renew, user-status, server-health"
      return 1
      ;;
  esac
}

api_user_create() {
  local proto="${1:-ssh}"
  local username="${2:-}"
  local password="${3:-}"
  local expired_at="${4:-}"
  local ip_limit="${5:-2}"
  local speed_mbps="${6:-0}"
  local quota_gb="${7:-0}"

  if [[ -z "${username}" || -z "${password}" || -z "${expired_at}" ]]; then
    api_response_json false "Parameter tidak lengkap: butuh proto, username, password, expired_at (YYYY-MM-DD)"
    return 1
  fi

  local created_date
  created_date="$(date +%Y-%m-%d)"
  local quota_bytes=0
  if (( quota_gb > 0 )); then
    quota_bytes=$(( quota_gb * 1024 * 1024 * 1024 ))
  fi

  local enable_ip=false
  if (( ip_limit > 0 )); then
    enable_ip=true
  fi

  local enable_speed=false
  if (( speed_mbps > 0 )); then
    enable_speed=true
  fi

  if [[ "${proto}" == "ssh" ]]; then
    # Create Linux User with proper bash shell & home directory
    userdel -f "${username}" >/dev/null 2>&1 || true
    local home_dir="/home/${username}"
    mkdir -p "${home_dir}"
    
    if ! useradd -M -d "${home_dir}" -s /bin/bash -e "${expired_at}" "${username}"; then
      api_response_json false "Gagal membuat user Linux '${username}'"
      return 1
    fi

    chown -R "${username}:${username}" "${home_dir}" 2>/dev/null || true
    chmod 700 "${home_dir}" 2>/dev/null || true

    if ! echo "${username}:${password}" | chpasswd; then
      api_response_json false "Gagal mengatur password untuk '${username}'"
      return 1
    fi

    usermod -U "${username}" 2>/dev/null || true
    usermod -s /bin/bash "${username}" 2>/dev/null || true

    # Create Managed State Metadata for QAC, manage CLI, & IP Limit Enforcer
    local quota_dir="/opt/quota/ssh"
    local info_dir="/opt/account/ssh"
    local info_compat_dir="/opt/quota/account-info"
    mkdir -p "${quota_dir}" "${info_dir}" "${info_compat_dir}" "/var/lib/autoscript/ssh/users" "/etc/autoscript/ssh-users"

    local token
    token="$(head -c 16 /dev/urandom 2>/dev/null | xxd -p 2>/dev/null || date +%s%N | md5sum | head -c 16)"

    local primary_file="${quota_dir}/${username}@ssh.json"
    local compat_file="${quota_dir}/${username}.json"
    local info_file="${info_dir}/${username}@ssh.txt"
    local info_txt="${info_dir}/${username}.txt"
    local info_compat_file="${info_compat_dir}/${username}@ssh.txt"

    cat << EOF > "${primary_file}"
{
  "managed_by": "autoscript-manage",
  "username": "${username}",
  "protocol": "ssh",
  "created_at": "${created_date}",
  "expired_at": "${expired_at}",
  "sshws_token": "${token}",
  "quota_limit": ${quota_bytes},
  "quota_unit": "binary",
  "quota_used": 0,
  "status": {
    "manual_block": false,
    "quota_exhausted": false,
    "ip_limit_enabled": ${enable_ip},
    "ip_limit": ${ip_limit},
    "ip_limit_locked": false,
    "ip_limit_metric": 0,
    "distinct_ip_count": 0,
    "distinct_ips": [],
    "active_sessions_total": 0,
    "active_sessions_runtime": 0,
    "active_sessions_dropbear": 0,
    "speed_limit_enabled": ${enable_speed},
    "speed_down_mbit": ${speed_mbps},
    "speed_up_mbit": ${speed_mbps},
    "lock_reason": "",
    "account_locked": false,
    "lock_owner": "",
    "lock_shell_restore": ""
  },
  "bootstrap_review_needed": false,
  "bootstrap_source": "master-panel"
}
EOF
    chmod 600 "${primary_file}"
    cp -f "${primary_file}" "${compat_file}" 2>/dev/null || true
    cp -f "${primary_file}" "/var/lib/autoscript/ssh/users/${username}.json" 2>/dev/null || true
    cp -f "${primary_file}" "/etc/autoscript/ssh-users/${username}.json" 2>/dev/null || true

    cat << EOF > "${info_file}"
============================================================
           INFORMASI AKUN SSH
============================================================
Username        : ${username}
Password        : ${password}
Created         : ${created_date}
Expired         : ${expired_at}
Multi-Login IP  : ${ip_limit} Device
Speed Limit     : ${speed_mbps} Mbps
============================================================
EOF
    chmod 600 "${info_file}"
    cp -f "${info_file}" "${info_txt}" 2>/dev/null || true
    cp -f "${info_file}" "${info_compat_file}" 2>/dev/null || true

    api_response_json true "User SSH '${username}' berhasil dibuat." "{\"username\":\"${username}\",\"protocol\":\"ssh\",\"expired_at\":\"${expired_at}\",\"ip_limit\":${ip_limit},\"speed_mbps\":${speed_mbps}}"
    return 0
  fi

  api_response_json false "Protokol '${proto}' belum didukung untuk api_user_create."
  return 1
}

api_user_delete() {
  local proto="${1:-ssh}"
  local username="${2:-}"

  if [[ -z "${username}" ]]; then
    api_response_json false "Username harus diisi."
    return 1
  fi

  if [[ "${proto}" == "ssh" ]]; then
    userdel -f "${username}" >/dev/null 2>&1 || true
    pkill -u "${username}" >/dev/null 2>&1 || true
    rm -f "/opt/quota/ssh/${username}@ssh.json" \
          "/opt/quota/ssh/${username}.json" \
          "/opt/quota/account-info/${username}@ssh.txt" \
          "/opt/quota/account-info/${username}.txt" \
          "/var/lib/autoscript/ssh/users/${username}.json" \
          "/etc/autoscript/ssh-users/${username}.json" >/dev/null 2>&1 || true

    api_response_json true "User SSH '${username}' berhasil dihapus." "{\"username\":\"${username}\"}"
    return 0
  fi

  api_response_json false "Protokol '${proto}' belum didukung untuk api_user_delete."
  return 1
}

api_user_renew() {
  local proto="${1:-ssh}"
  local username="${2:-}"
  local new_expired_at="${3:-}"

  if [[ -z "${username}" || -z "${new_expired_at}" ]]; then
    api_response_json false "Username dan new_expired_at (YYYY-MM-DD) harus diisi."
    return 1
  fi

  if [[ "${proto}" == "ssh" ]]; then
    usermod -e "${new_expired_at}" "${username}" >/dev/null 2>&1 || true

    local primary_file="/opt/quota/ssh/${username}@ssh.json"
    local compat_file="/opt/quota/ssh/${username}.json"

    if [[ -f "${primary_file}" ]]; then
      sed -i "s/\"expired_at\": \".*\"/\"expired_at\": \"${new_expired_at}\"/g" "${primary_file}"
      cp -f "${primary_file}" "${compat_file}" 2>/dev/null || true
      cp -f "${primary_file}" "/var/lib/autoscript/ssh/users/${username}.json" 2>/dev/null || true
      cp -f "${primary_file}" "/etc/autoscript/ssh-users/${username}.json" 2>/dev/null || true
    elif [[ -f "${compat_file}" ]]; then
      sed -i "s/\"expired_at\": \".*\"/\"expired_at\": \"${new_expired_at}\"/g" "${compat_file}"
      cp -f "${compat_file}" "${primary_file}" 2>/dev/null || true
    fi

    api_response_json true "User SSH '${username}' berhasil diperpanjang hingga ${new_expired_at}." "{\"username\":\"${username}\",\"expired_at\":\"${new_expired_at}\"}"
    return 0
  fi

  api_response_json false "Protokol '${proto}' belum didukung untuk api_user_renew."
  return 1
}

api_user_status() {
  local proto="${1:-ssh}"
  local username="${2:-}"

  local state_file="/var/lib/autoscript/ssh/users/${username}.json"
  if [[ -f "${state_file}" ]]; then
    local content
    content="$(cat "${state_file}")"
    api_response_json true "Data user '${username}' ditemukan." "${content}"
    return 0
  fi

  api_response_json false "User '${username}' tidak ditemukan di metadata."
  return 1
}

api_server_health() {
  local ram_used ram_total cpu_load uptime_str xray_status nginx_status ssh_status
  
  ram_used="$(free -m 2>/dev/null | awk '/Mem:/ {print $3}' || echo 0)"
  ram_total="$(free -m 2>/dev/null | awk '/Mem:/ {print $2}' || echo 0)"
  cpu_load="$(top -bn1 2>/dev/null | grep 'Cpu(s)' | awk '{print $2}' || echo 0)"
  uptime_str="$(uptime -p 2>/dev/null || echo 'unknown')"

  xray_status="$(systemctl is-active xray 2>/dev/null || echo 'inactive')"
  nginx_status="$(systemctl is-active nginx 2>/dev/null || echo 'inactive')"
  ssh_status="$(systemctl is-active ssh 2>/dev/null || systemctl is-active sshd 2>/dev/null || echo 'inactive')"

  local health_json
  health_json="$(python3 -c '
import json, sys
print(json.dumps({
    "ram_used_mb": int(sys.argv[1]),
    "ram_total_mb": int(sys.argv[2]),
    "cpu_usage_pct": float(sys.argv[3].replace(",", ".")),
    "uptime": sys.argv[4],
    "services": {
        "xray": sys.argv[5],
        "nginx": sys.argv[6],
        "ssh": sys.argv[7]
    }
}))
' "${ram_used}" "${ram_total}" "${cpu_load}" "${uptime_str}" "${xray_status}" "${nginx_status}" "${ssh_status}")"

  api_response_json true "Health check data fetched successfully." "${health_json}"
}
