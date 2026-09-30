# Manage Modules Documentation

Direktori ini berisi seluruh source modular untuk runtime CLI management (`manage`), router menu, background enforcer, serta script update VPS.

- **Source di Repo**: `opt/manage/...`
- **Target Deploy di VPS**: `/opt/manage/...` (dengan fallback `/usr/local/lib/autoscript-manage/opt/manage`)
- **Binary Entrypoint**: `manage.sh` $\rightarrow$ `/usr/local/bin/manage`
- **Updater Entrypoint**: `update.sh` $\rightarrow$ `/usr/local/bin/update`

---

## 1. Arsitektur & Struktur Direktori

Sistem CLI menggunakan pola modular yang memisahkan antara core bootstrap, handler fitur per domain, dan router menu visual.

```text
opt/manage/
├── app/
│   └── main.sh                      # Entrypoint utama runtime manage
├── core/
│   ├── env.sh                       # Variabel path & environment modular
│   ├── license.sh                   # Helper client license guard
│   ├── router.sh                    # CLI non-interactive dispatcher
│   └── ui.sh                        # Utility UI separator & frame
├── features/
│   ├── analytics.sh                 # Aggregator Traffic & Monitoring
│   ├── analytics/
│   │   └── traffic.sh               # Logika analitik & statistik bandwidth
│   ├── backup.sh                    # Backup & Restore konfigurasi
│   ├── domain.sh                    # Aggregator Domain Management
│   ├── domain/
│   │   ├── cloudflare.sh            # API & DNS record Cloudflare
│   │   └── control.sh               # Operasi & health-check domain VPS
│   ├── maintenance.sh               # Aggregator Maintenance & System Tools
│   ├── maintenance/
│   │   ├── banner.sh                # Customizer Banner SSH (/etc/issue.net) & MOTD
│   │   ├── diagnostics.sh           # Pemeriksaan kesehatan service
│   │   ├── logs.sh                  # Log viewer / realtime journal tail
│   │   ├── runtime_services.sh      # Control SSH, Dropbear & SSHWS
│   │   ├── security.sh              # Fail2ban, Firewall & SSL Hardening
│   │   ├── services.sh              # Service restart & recovery
│   │   ├── tools.sh                 # Submenu tools umum
│   │   └── updater.sh               # Sistem Auto-Update & Versioning
│   ├── network.sh                   # Aggregator Jaringan & Routing
│   ├── network/
│   │   ├── adblock.sh               # Adblocker terintegrasi (Xray + SSH)
│   │   ├── diagnostics.sh           # Network probe & latency checker
│   │   ├── dns.sh                   # DNS steering & upstream customizer
│   │   ├── routing.sh               # Routing rule engine Xray
│   │   ├── speedtest.sh             # Benchmark speedtest CLI
│   │   ├── ssh_network.sh           # Pengaturan Network & WARP SSH
│   │   └── warp.sh                  # WARP Free, Plus, & Zero Trust
│   ├── users.sh                     # Aggregator User & QAC Management
│   └── users/
│       ├── ssh_qac.sh               # Kuota, Multi-login limit, Speed SSH
│       ├── ssh_users.sh             # CRUD Akun SSH & Akun Trial (1 Hari)
│       ├── xray_qac.sh              # Quota & IP limiter Xray
│       └── xray_users.sh            # CRUD Akun Xray (VMess, VLess, Trojan)
└── menus/
    ├── domain_menu.sh               # Menu interaktif Domain Control
    ├── main_menu.sh                 # Menu interaktif utama & Panel Lisensi
    ├── maintenance_menu.sh          # Menu interaktif Maintenance
    ├── network_menu.sh              # Menu interaktif Xray Network
    └── user_menu.sh                 # Menu interaktif Akun Xray
```

---

## 2. Peta Source of Truth (Domain Mapping)

| Menu / Fitur | Source of Truth | Keterangan |
| :--- | :--- | :--- |
| **`1) Xray Users`** | `features/users/xray_users.sh` | Buat akun, perpanjang, hapus, detail info akun Xray. |
| **`2) SSH Users`** | `features/users/ssh_users.sh` | Buat akun SSH biasa & **Akun Trial 1 Hari**, reset password, manage session. |
| **`3) Xray QAC`** | `features/users/xray_qac.sh` | Quota Accounting & Enforcement limit Xray. |
| **`4) SSH QAC`** | `features/users/ssh_qac.sh` | Quota limit, IP limit, dan speed policy SSH. |
| **`5) Xray Network`** | `features/network/` | Pengaturan WARP global/per-user, DNS, and Geosite routing. |
| **`6) SSH Network`** | `features/network/ssh_network.sh` | DNS upstream SSH dan steering WARP SSH. |
| **`7) Adblocker`** | `features/network/adblock.sh` | Pemblokir iklan & malware shared untuk Xray + SSH. |
| **`8) Domain Control`**| `features/domain/control.sh` | Ganti domain, renewal sertifikat SSL acme.sh, Cloudflare sync. |
| **`9) Speedtest`** | `features/network/speedtest.sh` | Tes kecepatan server VPS via Ookla Speedtest. |
| **`10) Security`** | `features/maintenance/security.sh` | Fail2ban jail, port firewall, hardening SSH. |
| **`11) Maintenance`** | `features/maintenance/` | Restart core/services, live system journal, daemon watch. |
| **`12) Traffic`** | `features/analytics/traffic.sh` | Statistik traffic real-time & penggunaan bandwidth vnstat. |
| **`13) Tools > Bot`** | `/opt/bot-telegram` | Konfigurasi, sinkronisasi token, dan restart bot Telegram. |
| **`13) Tools > Banner`**| `features/maintenance/banner.sh` | Ganti Banner SSH (`/etc/issue.net`) & MOTD login terminal. |
| **`13) Tools > Update`**| `features/maintenance/updater.sh` | Auto-updater script via git/raw release & version checker. |
| **`13) Tools > Backup`**| `features/backup.sh` | Backup & Restore konfigurasi cloud / manual. |

---

## 3. UI Dashboard & Live Panel (`main_menu.sh`)

Dashboard menu utama telah didesain dengan aksen boxed panel modern:

1. **`[ SYSTEM INFO ]`**:
   - Menampilkan `IP VPS`, `DOMAIN`, `ISP`, `OS`, `UPTIME`, `CPU USAGE`, `RAM USAGE`, `DISK USAGE`, `SCRIPT VER` (`v1.0.0`), dan `SERVER TIME`.
2. **`[ BANDWIDTH ]`**:
   - Menampilkan total penggunaan traffic: `TODAY`, `YESTERDAY`, `MONTH`, dan `TOTAL`.
3. **`[ USER STATS ]`**:
   - Menghitung akun aktif: `VMESS`, `VLESS`, `TROJAN`, `SSWS`, `SSH`, `TOTAL`, dan `ONLINE SESSIONS`.
4. **`[ SERVICE ]`**:
   - Indikator status layanan live: `🟢 ONLINE` / `🔴 OFFLINE` untuk `XRAY`, `NGINX`, `DROPBEAR`, `SSH WS`, `EDGE MUX`, `WARP`, `STUNNEL`, dan `BADVPN`.
5. **`[ MAIN MENU ]`**:
   - Penomoran rapi 2 kolom `[01]` s/d `[13]`, dan `[00]` Keluar.
6. **`[ LICENSE ]`**:
   - Menampilkan status lisensi di bagian paling bawah (`License`, `Type: Lifetime Premium`, `Status: ACTIVE`).

---

## 4. Sistem Versi & Auto-Updater

### Komponen:
- **`version`**: File penanda versi (contoh `1.0.0` di `/etc/autoscript/version`).
- **`changelog.txt`**: File catatan riwayat pembaruan yang dibaca otomatis oleh panel updater.
- **`update.sh`**: Standalone script di root repo yang terpasang ke `/usr/local/bin/update`.
- **`updater.sh`**: Modul manajemen untuk perbandingan semver lokal vs remote GitHub.

### Alur Kerja Update:
1. Operator mengetik `update` di terminal atau memilih menu **13) Tools $\rightarrow$ 6|Update Script**.
2. Script membandingkan versi lokal dengan versi rilis terbaru di repository GitHub.
3. Melakukan backup cepat modul aktif ke `/var/backups/`.
4. Mengunduh dan mereplace modul `/opt/manage/` dan executable `/usr/local/bin/manage` tanpa merusak data akun, sertifikat SSL, database, atau lisensi VPS.
5. Memeriksa dan menginstal paket dependensi baru yang diperlukan.
6. Me-reload systemd daemon dan mencatat versi baru.

---

## 5. Panduan Maintainer & Developer

1. **Prinsip Modular**:
   - Jangan menambahkan logic kompleks langsung ke file aggregator `features/*.sh` atau `manage.sh`.
   - Buat sub-file di folder domain masing-masing (contoh: fitur SSH baru di `features/users/ssh_*.sh`).
2. **Rebuild Archive**:
   - Setelah memodifikasi modul `opt/manage` atau `bot-telegram`, jalankan:
     ```bash
     python3 tools/rebuild_bot_archives.py
     ```
   - Script ini akan memperbarui `manage_bundle.zip` dan `bot_telegram.zip` secara otomatis.
3. **Pengujian Lokal di VPS**:
   - Untuk menguji perubahan langsung dari working directory git tanpa replace manual:
     ```bash
     RUN_USE_LOCAL_SOURCE=1 bash run.sh
     ```
   - Jalankan `manage` untuk memverifikasi UI dan fungsi menu.
