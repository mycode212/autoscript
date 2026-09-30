# Autoscript

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Linux-0f172a?style=for-the-badge&logo=linux&logoColor=white" alt="Linux">
  <img src="https://img.shields.io/badge/Core-Xray-111827?style=for-the-badge&logo=radar&logoColor=white" alt="Xray">
  <img src="https://img.shields.io/badge/Edge-Go%20edge--mux-0b5fff?style=for-the-badge&logo=go&logoColor=white" alt="Go edge-mux">
  <img src="https://img.shields.io/badge/Remote-Telegram-229ED9?style=for-the-badge&logo=telegram&logoColor=white" alt="Telegram">
  <img src="https://img.shields.io/badge/WARP-Cloudflare-F38020?style=for-the-badge&logo=cloudflare&logoColor=white" alt="Cloudflare WARP">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Manage-CLI%20v1.0.0-1f2937?style=flat-square&logo=gnubash&logoColor=white" alt="Manage CLI">
  <img src="https://img.shields.io/badge/UI-Boxed%20Style-10b981?style=flat-square&logo=gnometerminal&logoColor=white" alt="Boxed UI">
  <img src="https://img.shields.io/badge/Portal-Account-2563eb?style=flat-square&logo=vercel&logoColor=white" alt="Account Portal">
  <img src="https://img.shields.io/badge/Access-SSH%2FWebSocket-0ea5e9?style=flat-square&logo=protonvpn&logoColor=white" alt="SSH WebSocket">
  <img src="https://img.shields.io/badge/Utility-BadVPN-475569?style=flat-square&logo=wireguard&logoColor=white" alt="BadVPN">
  <img src="https://img.shields.io/badge/Support-Backup%20%26%20Restore-0f766e?style=flat-square&logo=icloud&logoColor=white" alt="Backup and Restore">
  <img src="https://img.shields.io/badge/Updater-Auto%20Update-f59e0b?style=flat-square&logo=git&logoColor=white" alt="Auto Updater">
</p>

---

## 📌 Ringkasan Proyek

**Autoscript** adalah repositori lengkap serba otomatis untuk membangun, mengelola, dan memelihara server tunneling VPN & SSH di VPS Linux (Ubuntu / Debian). Dilengkapi dengan ingress edge multiplexer modern, bot Telegram remote control, portal akun read-only, manajemen kuota/QAC cerdas, kustomisasi banner, dashboard CLI bertema panel modern, serta sistem auto-updater mandiri.

* **`run.sh`**: Installer otomatis bootstrap VPS dari nol.
* **`manage` / `manage.sh`**: CLI panel kontrol operasional harian.
* **`update` / `update.sh`**: Script pembaruan otomatis (hot-reload modul tanpa menghapus data akun/lisensi).
* **`install-telegram-bot`**: Installer & controller Bot Telegram terintegrasi.

---

## 📋 Persyaratan Sistem (System Requirements)

Pastikan VPS Anda memenuhi kriteria berikut sebelum memulai instalasi:

### 1. Sistem Operasi (OS) yang Didukung
| Distribusi Linux | Versi yang Didukung | Rekomendasi |
| :--- | :--- | :--- |
| **Ubuntu** | `20.04 LTS (Focal)`, `22.04 LTS (Jammy)`, `24.04 LTS (Noble)` | ✅ Ubuntu 22.04 LTS |
| **Debian** | `11 (Bullseye)`, `12 (Bookworm)` | ✅ Debian 12 |

> *Catatan:* Disarankan menggunakan instalasi Linux versi **Clean / Fresh Install (Minimal OS)** tanpa web server atau panel kontrol lain yang sedang aktif (misalnya cPanel, aaPanel, Apache) agar tidak terjadi konflik port 80/443.

### 2. Spesifikasi Perangkat Keras (Hardware)
* **Arsitektur CPU**: `x86_64` (AMD64) / `aarch64` (ARM64)
* **Processor (CPU)**: Minimal 1 Core ($\ge$ 1.0 GHz)
* **Memori (RAM)**:
  * Minimal: **512 MB** (dengan swap aktif)
  * Rekomendasi: **1 GB atau lebih** untuk performa optimal & bot Telegram
* **Ruang Disk (Storage)**: Minimal **5 GB** sisa ruang kosong
* **Virtualisasi**: KVM, VMware, Proxmox, Xen, OpenVZ, Dedicated Server

### 3. Persyaratan Jaringan & Domain
* **IP VPS**: Wajib memiliki **1x Alamat IPv4 Publik Statis**.
* **Port Terbuka**: Port `80` (HTTP) dan `443` (HTTPS) tidak diblokir oleh provider VPS / firewall.
* **Domain**: 1 Domain / Subdomain aktif dengan DNS **A Record** yang sudah mengarah ke IP publik VPS (disarankan DNS Cloudflare dengan status *DNS Only / Proxied Off* saat instalasi awal sertifikat SSL).

---

## ⚡ Quick Start

### 1. Persiapan Lisensi VPS
Sebelum menjalankan installer, daftarkan dan aktifkan IPv4 publik VPS Anda di portal lisensi:
* **Portal Lisensi**: `https://autoscript.license.dpdns.org`
* Cukup masukkan IP VPS, selesaikan verifikasi, dan pastikan status IP sudah aktif.

### 2. Instalasi Baru (Fresh Install)
Jalankan perintah berikut di terminal VPS (sebagai root):
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/mycode212/autoscript/refs/heads/main/run.sh)
```

### 3. Pembaruan Script (Auto-Update)
Jika script sudah terpasang di VPS, Anda dapat melakukan pembaruan ke versi terbaru kapan saja hanya dengan mengetik:
```bash
update
```
*atau melalui URL*:
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/mycode212/autoscript/refs/heads/main/update.sh)
```

---

## 🖥️ Tampilan Dashboard Management (`manage`)

Dashboard CLI `manage` dirancang dengan layout kotak modern (*boxed panel*) yang rapi dan informatif:

```text
╭──────────────────────[ SYSTEM INFO ]───────────────────────╮
│  IP VPS         : 103.253.xxx.xxx                          │
│  DOMAIN         : xray.domainanda.net                      │
│  ISP            : PT Dewa Bisnis Digital                   │
│  OS             : Debian GNU/Linux 12 (bookworm)           │
│  UPTIME         : 15 hours, 51 minutes                     │
│  CPU USAGE      : 1%                                       │
│  RAM USAGE      : 865MB / 973MB                            │
│  DISK USAGE     : 6.2G / 20G (31%)                         │
│  SCRIPT VER     : v1.0.0                                   │
│  SERVER TIME    : 30-09-2026 10:15:00                      │
╰────────────────────────────────────────────────────────────╯
╭──────────────────────[ BANDWIDTH ]─────────────────────────╮
│  TODAY     : 5.62 GiB        YESTERDAY  : 2.90 GiB         │
│  MONTH     : 71.50 GiB       TOTAL      : 267.91 GiB       │
╰────────────────────────────────────────────────────────────╯
╭──────────────────────[ USER STATS ]────────────────────────╮
│  VMESS : 3          VLESS : 1          TROJAN : 0          │
│  SSWS  : 0          SSH   : 4          TOTAL  : 8          │
│  ONLINE SESSIONS   : 2                                     │
╰────────────────────────────────────────────────────────────╯
╭───────────────────────[ SERVICE ]──────────────────────────╮
│  XRAY       : 🟢 ONLINE   NGINX     : 🟢 ONLINE            │
│  DROPBEAR   : 🟢 ONLINE   SSH WS    : 🟢 ONLINE            │
│  EDGE MUX   : 🟢 ONLINE   WARP      : 🟢 ONLINE            │
│  STUNNEL    : 🟢 ONLINE   BADVPN    : 🟢 ONLINE            │
╰────────────────────────────────────────────────────────────╯
╭──────────────────────[ MAIN MENU ]─────────────────────────╮
│  [01] Xray Users             [08] Domain Control           │
│  [02] SSH Users              [09] Speedtest                │
│  [03] Xray QAC               [10] Security                 │
│  [04] SSH QAC                [11] Maintenance              │
│  [05] Xray Network           [12] Traffic                  │
│  [06] SSH Network            [13] Tools                    │
│  [07] Adblocker              [00] Keluar                   │
╰────────────────────────────────────────────────────────────╯
╭───────────────────────[ LICENSE ]──────────────────────────╮
│  License    : 103.253.xxx.xxx                              │
│  Type       : Lifetime Premium                             │
│  Status     : ACTIVE (Lifetime Premium)                    │
╰────────────────────────────────────────────────────────────╯

Select Menu : 
```

---

## 🚀 Fitur Unggulan

### 1. Protokol & Layanan Terowongan (Tunneling)
* **Xray-Core**: Mendukung `VMess`, `VLESS`, dan `Trojan` dengan beragam transport:
  * `WebSocket (WS)`
  * `gRPC`
  * `HTTPUpgrade (HUP)`
  * `XHTTP` / `XHTTP3 (QUIC)`
  * `TCP + TLS`
* **SSH Stack Lengkap**:
  * `SSH Direct (Dropbear / OpenSSH)`
  * `SSH SSL/TLS (Stunnel)`
  * `SSH WebSocket (Go WS Proxy)` pada port HTTP (80) dan HTTPS (443)
* **Akun SSH Trial Otomatis**: Fitur pembuatan akun trial 1 hari instan dengan generator username/password acak via CLI dan Bot Telegram.
* **BadVPN UDPGW**: Mendukung video call, gaming, dan voice chat UDP pada port `7300-7900`.
* **WARP & Zero Trust**: Dukungan Cloudflare WARP Free, WARP Plus, serta WARP Zero Trust (`cloudflare-warp` local proxy) dengan steering per-user.

### 2. Kustomisasi & Branding Server
* **Banner SSH Customizer (`/etc/issue.net`)**:
  * Input teks manual dengan preview instan.
  * Template HTML warna-warni siap pakai.
  * Unduh banner langsung dari link URL eksternal.
* **MOTD Login Customizer (`/etc/motd`)**:
  * Template banner status server saat login SSH terminal.

### 3. Sistem Versi & Pembaruan Otomatis
* **Deteksi Versi Real-time**: Membandingkan versi terpasang di VPS (`/etc/autoscript/version`) dengan versi rilis terbaru di GitHub.
* **CLI Updater (`update`)**: Eksekusi update langsung dengan auto-backup konfigurasi lama, sinkronisasi modul baru, auto-install requirement/dependensi baru, dan restart service tanpa downtime client.
* **Changelog Tracker**: Catatan riwayat rilis terpisah pada [`changelog.txt`](changelog.txt).

### 4. Manajemen Akun, Kuota, & Keamanan (QAC)
* **QAC Engine**: Limit kuota bandwidth (GB), masa aktif (Expired cleaner), batas login simultan (Multi-login / IP limit), dan pembatas kecepatan (Speed limit).
* **Adblocker Terpadu**: Blokir iklan, malware, dan tracker otomatis untuk semua koneksi Xray & SSH.
* **Security Hardening**: Proteksi Fail2ban terintegrasi, firewall port, dan validasi sertifikat otomatis.

### 5. Remote Bot Telegram & Account Portal
* **Bot Telegram Interaktif**: Kontrol VPS dari HP: buat akun biasa/trial, cek user aktif, ganti banner, restart service, backup cloud, dan cek resource.
* **Web Account Portal**: Tautan portal akun read-only untuk client melihat sisa kuota, masa aktif, dan unduh config.

---

## 🗂️ Navigasi Menu CLI `manage`

| Menu | Sub-Fitur Utama |
| :--- | :--- |
| **`[01] Xray Users`** | Tambah akun, perpanjang, hapus, ganti UUID, list akun, cek login aktif Xray. |
| **`[02] SSH Users`** | Tambah akun SSH, **Trial User (1 Hari)**, perpanjang, hapus, reset password, lock/unlock user, kill multi-login. |
| **`[03] Xray QAC`** | Konfigurasi kuota Xray, batas IP per akun, speed limiter, status limit. |
| **`[04] SSH QAC`** | Konfigurasi kuota SSH, batasan login IP, speed policy per-user. |
| **`[05] Xray Network`**| Override WARP (direct/warp/global), DNS upstream, diagnostics network. |
| **`[06] SSH Network`** | DNS steering SSH, mode WARP SSH global dan per-user. |
| **`[07] Adblocker`** | Aktifkan/nonaktifkan pemblokir iklan, tambah URL filter list kustom, auto-update. |
| **`[08] Domain Control`**| Ubah domain VPS, renew SSL acme.sh, Cloudflare API sync, perbaikan DNS drift. |
| **`[09] Speedtest`** | Tes kecepatan bandwidth server lokal/internasional via Ookla. |
| **`[10] Security`** | Pengaturan Fail2ban, manajemen sertifikat TLS, tuning kernel/firewall. |
| **`[11] Maintenance`** | Restart Core (Xray + Nginx), live log viewer (journalctl), restart background daemon. |
| **`[12] Traffic`** | Analitik traffic harian/bulanan via vnstat dan session watcher. |
| **`[13] Tools`** | **Telegram Bot**, **WARP Tier**, **License Guard**, **Backup/Restore Cloud**, **Banner SSH & MOTD**, **Update Script**, dan **Uninstall**. |

---

## 🌐 Port & Jalur Akses (Ingress Architecture)

Semua traffic publik masuk melalui single edge multiplexer (`edge-mux` di port 80 & 443 beserta port alternatif Cloudflare) lalu dialihkan secara cerdas ke backend lokal:

```text
Internet / Cloudflare
        │
        ▼
  edge-mux (Go Multiplexer)
  HTTP : 80, 8080, 8880, 2052, 2082, 2086, 2095
  HTTPS: 443, 2053, 2083, 2087, 2096, 8443
        │
        ├──► Nginx (HTTP internal)       : 127.0.0.1:18080
        ├──► SSH Dropbear (Direct)       : 127.0.0.1:22022
        ├──► SSH Stunnel (TLS)           : 127.0.0.1:22443
        ├──► SSH WS Proxy (Go)           : 127.0.0.1:10015
        └──► Xray Core (VLESS/VMess/Trj) : Inbound internal runtime
```

### Path Publik Client yang Stabil
* **SSH WS**: `/<token-hex-10>`
* **VLESS WS**: `/vless-ws`
* **VLESS gRPC**: `/vless-grpc`
* **VLESS HUP / XHTTP**: `/vless-hup`, `/vless-xhttp`
* **VMess WS**: `/vmess-ws`
* **VMess gRPC**: `/vmess-grpc`
* **VMess HUP / XHTTP**: `/vmess-hup`, `/vmess-xhttp`
* **Trojan WS**: `/trojan-ws`
* **Trojan gRPC**: `/trojan-grpc`

---

## 💾 Cloud Backup & Restore

Mendukung pencadangan data akun, sertifikat SSL, konfigurasi, dan database kuota secara otomatis atau manual:
* **Pilihan Cloud Provider**:
  * `Google Drive` (via Service Account / OAuth)
  * `Cloudflare R2` (S3 Compatible Storage)
  * `Telegram Cloud` (Kirim backup langsung ke chat admin)
* **Fitur Restore Cerdas**: Dilengkapi *safety backup* otomatis sebelum restore dan auto-rollback jika terjadi kegagalan validasi.

---

## 🛠️ Pengembangan & Pengujian Lokal

Untuk maintainer yang mengembangkan fitur secara lokal di VPS:
```bash
# Menjalankan installer menggunakan file repo lokal tanpa fetch GitHub
RUN_USE_LOCAL_SOURCE=1 bash run.sh

# Melakukan rebuild arsip zip bot & bundle manage setelah modifikasi kode
python3 tools/rebuild_bot_archives.py

# Menjalankan update script lokal
bash update.sh
```

---

## 📄 Lisensi

Source code repositori ini dilisensikan di bawah **[GPL-3.0-or-later](LICENSE)**. Bebas digunakan, dipelajari, dan dikembangkan lebih lanjut dengan tetap menyertakan atribusi sumber terbuka.
