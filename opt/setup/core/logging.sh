#!/usr/bin/env bash
# Shared logging/UI helpers for modular setup runtime.

declare -ag _EXIT_CLEANUP_FNS=()

die() {
  echo -e "${RED}[ERROR]${NC} $*" >&2
  exit 1
}

ok() {
  echo -e "${GREEN}[OK]${NC} $*"
}

warn() {
  echo -e "${YELLOW}[WARN]${NC} $*"
}

run_exit_cleanups() {
  local rc=$?
  local fn
  for fn in "${_EXIT_CLEANUP_FNS[@]}"; do
    if declare -F "$fn" >/dev/null 2>&1; then
      "$fn" || true
    fi
  done
  return "$rc"
}

register_exit_cleanup() {
  local fn="$1"
  local existing
  for existing in "${_EXIT_CLEANUP_FNS[@]}"; do
    [[ "$existing" == "$fn" ]] && return 0
  done
  _EXIT_CLEANUP_FNS+=("$fn")
}

safe_clear() {
  if [[ -t 1 ]] && command -v clear >/dev/null 2>&1; then
    clear || true
  fi
}

ui_hr() {
  local w="${COLUMNS:-80}"
  local line
  if [[ ! "${w}" =~ ^[0-9]+$ ]]; then
    w=80
  fi
  if (( w < 60 )); then
    w=60
  fi
  printf -v line '%*s' "${w}" ''
  line="${line// /-}"
  echo -e "${DIM}${line}${NC}"
}

ui_header() {
  local text="$1"
  safe_clear
  ui_hr
  echo -e "${BOLD}${CYAN}${text}${NC}"
  ui_hr
}

ui_subtle() {
  echo -e "${DIM}$*${NC}"
}

ui_section_title() {
  local text="$1"
  echo -e "${BOLD}${text}${NC}"
}

ui_spinner_wait() {
  local pid="$1"
  local label="${2:-Memproses}"
  local status_file="${3:-}"
  local start_ts now elapsed frame_idx rc
  local -a frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
  local current_label last_printed_label step_start_ts step_elapsed formatted_time

  if [[ ! "${pid}" =~ ^[0-9]+$ ]]; then
    return 1
  fi

  if [[ ! -t 1 ]]; then
    wait "${pid}"
    return $?
  fi

  # Sembunyikan kursor selama proses berlangsung
  printf '\033[?25l' 2>/dev/null || true

  start_ts="$(date +%s 2>/dev/null || echo 0)"
  step_start_ts="${start_ts}"
  last_printed_label=""
  current_label="${label}"
  frame_idx=0

  while kill -0 "${pid}" 2>/dev/null; do
    now="$(date +%s 2>/dev/null || echo "${start_ts}")"

    # Cek apakah ada update status step baru dari background worker
    if [[ -n "${status_file}" && -r "${status_file}" ]]; then
      local status_line=""
      status_line="$(head -n1 "${status_file}" 2>/dev/null | tr -d '\r' || true)"
      if [[ -n "${status_line}" && "${status_line}" != "${current_label}" ]]; then
        # Jika sebelumnya sudah ada step yang berjalan, cetak tanda selesai (✔) untuk step tersebut
        if [[ -n "${last_printed_label}" ]]; then
          step_elapsed=$(( now - step_start_ts ))
          if (( step_elapsed >= 60 )); then
            formatted_time="$(( step_elapsed / 60 ))m $(( step_elapsed % 60 ))s"
          else
            formatted_time="${step_elapsed}s"
          fi
          printf '\r\033[2K  \033[0;32m✔\033[0m \033[0;37m%s\033[0m \033[0;36m(%s)\033[0m\n' "${last_printed_label}" "${formatted_time}"
        fi
        last_printed_label="${status_line}"
        current_label="${status_line}"
        step_start_ts="${now}"
      fi
    fi

    if [[ -z "${last_printed_label}" ]]; then
      last_printed_label="${current_label}"
    fi

    elapsed=$(( now - step_start_ts ))
    if (( elapsed >= 60 )); then
      formatted_time="$(( elapsed / 60 ))m $(( elapsed % 60 ))s"
    else
      formatted_time="${elapsed}s"
    fi

    # Tampilkan spinner untuk step yang sedang aktif berjalan
    printf '\r\033[2K  \033[1;36m%s\033[0m \033[1;37m%s\033[0m \033[0;36m(%s)\033[0m' \
      "${frames[$frame_idx]}" "${current_label}" "${formatted_time}"
    frame_idx=$(( (frame_idx + 1) % ${#frames[@]} ))
    sleep 0.08
  done

  wait "${pid}"
  rc=$?

  now="$(date +%s 2>/dev/null || echo "${start_ts}")"
  step_elapsed=$(( now - step_start_ts ))
  if (( step_elapsed >= 60 )); then
    formatted_time="$(( step_elapsed / 60 ))m $(( step_elapsed % 60 ))s"
  else
    formatted_time="${step_elapsed}s"
  fi

  if (( rc == 0 )); then
    if [[ -n "${current_label}" ]]; then
      printf '\r\033[2K  \033[0;32m✔\033[0m \033[0;37m%s\033[0m \033[0;36m(%s)\033[0m\n' "${current_label}" "${formatted_time}"
    fi
  else
    if [[ -n "${current_label}" ]]; then
      printf '\r\033[2K  \033[0;31m✖\033[0m \033[0;31m%s (Gagal)\033[0m\n' "${current_label}"
    fi
  fi

  # Kembalikan kursor
  printf '\033[?25h' 2>/dev/null || true
  return "${rc}"
}
