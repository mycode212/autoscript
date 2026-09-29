#!/usr/bin/env bash

BADVPN_DIST_DIR="${SCRIPT_DIR}/opt/badvpn/dist"
BADVPN_RUNTIME_ENV_FILE="${BADVPN_RUNTIME_ENV_FILE:-/etc/default/badvpn-udpgw}"
BADVPN_RUNTIME_ENV_TEMPLATE="${SETUP_TEMPLATE_SRC_DIR}/config/badvpn-runtime.env"
BADVPN_SERVICE_TEMPLATE="${SETUP_TEMPLATE_SRC_DIR}/systemd/badvpn-udpgw.service"
BADVPN_BIN_INSTALL_PATH="${BADVPN_BIN_INSTALL_PATH:-/usr/local/bin/badvpn-udpgw}"
BADVPN_LAUNCHER_SRC="${SCRIPT_DIR}/opt/setup/bin/badvpn-udpgw-launcher.sh"
BADVPN_LAUNCHER_INSTALL_PATH="${BADVPN_LAUNCHER_INSTALL_PATH:-/usr/local/bin/badvpn-udpgw-launcher}"
BADVPN_SERVICE_NAME="${BADVPN_SERVICE_NAME:-badvpn-udpgw.service}"
BADVPN_UDPGW_PORTS_DEFAULT="${BADVPN_UDPGW_PORTS_DEFAULT:-7300 7400 7500 7600 7700 7800 7900}"

badvpn_runtime_expected() {
  badvpn_prebuilt_ready && [[ -x "${BADVPN_BIN_INSTALL_PATH}" ]] && "${BADVPN_BIN_INSTALL_PATH}" --help >/dev/null 2>&1
}

badvpn_arch_label() {
  case "$(uname -m)" in
    x86_64|amd64) echo "amd64" ;;
    aarch64|arm64) echo "arm64" ;;
    *) return 1 ;;
  esac
}

badvpn_expected_binary_path() {
  local arch
  arch="$(badvpn_arch_label)" || return 1
  printf '%s/badvpn-udpgw-linux-%s\n' "${BADVPN_DIST_DIR}" "${arch}"
}

badvpn_prebuilt_ready() {
  local bin
  bin="$(badvpn_expected_binary_path)" || return 1
  [[ -f "${bin}" ]] || return 1
  return 0
}

test_badvpn_binary() {
  local bin="${1:-${BADVPN_BIN_INSTALL_PATH}}"
  [[ -x "${bin}" ]] || return 1
  "${bin}" --help >/dev/null 2>&1 || return 1
  return 0
}

build_badvpn_from_source() {
  ok "Mengompilasi badvpn-udpgw dari source untuk kompatibilitas libc sistem..."
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -y >/dev/null 2>&1 || true
  apt-get install -y --no-install-recommends cmake make gcc libc6-dev libssl-dev git >/dev/null 2>&1 || {
    warn "Gagal menginstal build dependencies untuk badvpn-udpgw."
    return 1
  }

  local build_dir
  build_dir="$(mktemp -d /tmp/badvpn-build.XXXXXX)"
  if ! git clone --depth 1 https://github.com/ambrop72/badvpn.git "${build_dir}/src" >/dev/null 2>&1; then
    rm -rf "${build_dir}"
    warn "Gagal clone repo badvpn dari GitHub."
    return 1
  fi

  mkdir -p "${build_dir}/build"
  (
    cd "${build_dir}/build" || exit 1
    cmake ../src -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 >/dev/null 2>&1
    make badvpn-udpgw >/dev/null 2>&1
  ) || {
    rm -rf "${build_dir}"
    warn "Kompilasi cmake make badvpn-udpgw gagal."
    return 1
  }

  local compiled_bin="${build_dir}/build/udpgw/badvpn-udpgw"
  if [[ -f "${compiled_bin}" ]] && "${compiled_bin}" --help >/dev/null 2>&1; then
    install -m 0755 "${compiled_bin}" "${BADVPN_BIN_INSTALL_PATH}"
    chown root:root "${BADVPN_BIN_INSTALL_PATH}" 2>/dev/null || true
    rm -rf "${build_dir}"
    ok "Kompilasi badvpn-udpgw berhasil dipasang."
    return 0
  fi

  rm -rf "${build_dir}"
  return 1
}

write_badvpn_runtime_env() {
  if [[ -f "${BADVPN_RUNTIME_ENV_TEMPLATE}" ]]; then
    render_setup_template_or_die "config/badvpn-runtime.env" "${BADVPN_RUNTIME_ENV_FILE}" 0644
  else
    cat > "${BADVPN_RUNTIME_ENV_FILE}" <<'EOF'
BADVPN_UDPGW_PORTS="7300 7400 7500 7600 7700 7800 7900"
BADVPN_UDPGW_MAX_CLIENTS=512
BADVPN_UDPGW_MAX_CONNECTIONS_FOR_CLIENT=8
BADVPN_UDPGW_BUFFER_SIZE=1048576
EOF
  fi
}

install_badvpn_udpgw_stack() {
  local bin src_name
  if ! badvpn_prebuilt_ready; then
    warn "Binary prebuilt BadVPN UDPGW belum ada. Mencoba kompilasi dari source..."
    if ! build_badvpn_from_source; then
      warn "BadVPN UDPGW dilewati."
      return 0
    fi
  else
    bin="$(badvpn_expected_binary_path)" || {
      warn "Arsitektur host belum didukung untuk BadVPN UDPGW."
      return 0
    }
    src_name="$(basename "${bin}")"
    install -d -m 755 "$(dirname "${BADVPN_BIN_INSTALL_PATH}")"
    install -m 0755 "${bin}" "${BADVPN_BIN_INSTALL_PATH}"
    chown root:root "${BADVPN_BIN_INSTALL_PATH}" 2>/dev/null || true
  fi

  if ! test_badvpn_binary "${BADVPN_BIN_INSTALL_PATH}"; then
    warn "Binary prebuilt badvpn-udpgw tidak cocok dengan glibc sistem. Mengompilasi ulang..."
    if ! build_badvpn_from_source; then
      warn "BadVPN UDPGW tidak dapat dijalankan pada versi libc host ini. Dilewati."
      return 0
    fi
  fi

  if [[ ! -f "${BADVPN_SERVICE_TEMPLATE}" ]]; then
    die "Template service BadVPN UDPGW tidak ditemukan: ${BADVPN_SERVICE_TEMPLATE}"
  fi

  install -m 0755 "${BADVPN_LAUNCHER_SRC}" "${BADVPN_LAUNCHER_INSTALL_PATH}"
  chown root:root "${BADVPN_LAUNCHER_INSTALL_PATH}" 2>/dev/null || true

  write_badvpn_runtime_env
  render_setup_template_or_die \
    "systemd/badvpn-udpgw.service" \
    "/etc/systemd/system/${BADVPN_SERVICE_NAME}" \
    0644 \
    "BADVPN_BIN_INSTALL_PATH=${BADVPN_BIN_INSTALL_PATH}" \
    "BADVPN_LAUNCHER_INSTALL_PATH=${BADVPN_LAUNCHER_INSTALL_PATH}" \
    "BADVPN_RUNTIME_ENV_FILE=${BADVPN_RUNTIME_ENV_FILE}"

  systemctl stop "${BADVPN_SERVICE_NAME}" >/dev/null 2>&1 || true
  pkill -9 -x badvpn-udpgw >/dev/null 2>&1 || true
  systemctl daemon-reload >/dev/null 2>&1 || true

  if ! service_enable_restart_checked "${BADVPN_SERVICE_NAME}"; then
    systemctl status "${BADVPN_SERVICE_NAME}" --no-pager >&2 || true
    journalctl -u "${BADVPN_SERVICE_NAME}" -n 50 --no-pager >&2 || true
    warn "${BADVPN_SERVICE_NAME} gagal diaktifkan. Setup dilanjutkan tanpa BadVPN."
    systemctl disable --now "${BADVPN_SERVICE_NAME}" >/dev/null 2>&1 || true
    return 0
  fi
  ok "BadVPN UDPGW aktif"
}
