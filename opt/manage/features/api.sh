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
    # Create Linux User
    userdel -f "${username}" >/dev/null 2>&1 || true
    if ! useradd -e "${expired_at}" -s /bin/false -M "${username}"; then
      api_response_json false "Gagal membuat user Linux '${username}'"
      return 1
    fi

    if ! echo "${username}:${password}" | chpasswd; then
      api_response_json false "Gagal mengatur password untuk '${username}'"
      return 1
    fi

    # Create Managed State Metadata for QAC & IP Limit Enforcer
    local state_dir="/var/lib/autoscript/ssh/users"
    local compat_dir="/etc/autoscript/ssh-users"
    mkdir -p "${state_dir}" "${compat_dir}" "/etc/autoscript/ssh/account-info"

    local state_file="${state_dir}/${username}.json"
    cat << EOF > "${state_file}"
{
  "managed_by": "autoscript-api",
  "username": "${username}",
  "protocol": "ssh",
  "created_at": "${created_date}",
  "expired_at": "${expired_at}",
  "quota_limit": ${quota_bytes},
  "quota_unit": "binary",
  "quota_used": 0,
  "status": {
    "manual_block": false,
    "quota_exhausted": false,
    "ip_limit_enabled": ${enable_ip},
    "ip_limit": ${ip_limit},
    "ip_limit_locked": false,
    "speed_limit_enabled": ${enable_speed},
    "speed_down_mbit": ${speed_mbps},
    "speed_up_mbit": ${speed_mbps},
    "account_locked": false
  }
}
EOF
    chmod 600 "${state_file}"
    cp -f "${state_file}" "${compat_dir}/${username}.json" 2>/dev/null || true

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
    rm -f "/var/lib/autoscript/ssh/users/${username}.json" "/etc/autoscript/ssh-users/${username}.json" "/etc/autoscript/ssh/account-info/${username}.txt" >/dev/null 2>&1 || true

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

    local state_file="/var/lib/autoscript/ssh/users/${username}.json"
    if [[ -f "${state_file}" ]]; then
      sed -i "s/\"expired_at\": \".*\"/\"expired_at\": \"${new_expired_at}\"/g" "${state_file}"
      cp -f "${state_file}" "/etc/autoscript/ssh-users/${username}.json" 2>/dev/null || true
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
