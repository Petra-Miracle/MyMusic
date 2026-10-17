# Nada

Aplikasi pemutar musik pribadi (Flutter). Lagu dicari & diputar langsung dari YouTube di HP;
backend (Express + Prisma + Neon di Vercel) hanya menyimpan akun, playlist, like, dan riwayat.

## Download (Android)

**[⬇ Download Nada untuk Android](https://github.com/Petra-Miracle/MyMusic/releases/latest/download/Nada-arm64.apk)** (±22 MB, untuk hampir semua HP Android modern)

HP lama / gagal install? Coba [Nada-armv7.apk](https://github.com/Petra-Miracle/MyMusic/releases/latest/download/Nada-armv7.apk)
atau versi universal [Nada.apk](https://github.com/Petra-Miracle/MyMusic/releases/latest/download/Nada.apk) (±59 MB).

Pendaftaran butuh **kode undangan** — minta ke teman yang sudah punya akun (Profil → Buat kode undangan).

## Menjalankan

```bash
flutter pub get
flutter run                          # HP Android (USB debugging) / emulator, data asli
flutter run --dart-define=USE_MOCK=true   # data contoh, tanpa backend
```

Dengan data contoh: username apa saja, password minimal 4 karakter (password `salah` untuk melihat
state error). Kode undangan contoh: format `NADA-XXXXX`.

## Struktur

```
lib/
  app/            theme (token dari mockup), router, config (URL backend)
  core/widgets/   komponen design system: TrackTile, MiniPlayer, BottomNav, Chip, Button, Sheet, Toast…
  data/
    models/       Track, Playlist, HistoryEntry, AppUser (sama dengan schema Prisma)
    repositories/ kontrak data — setiap method diberi komentar endpoint API
    api/          implementasi ke backend (dio + token di secure storage)
    youtube/      search, lagu serupa & URL audio (youtube_explode_dart) + perapi judul
    lyrics/       lirik tersinkron dari LRCLIB
    mock/         data contoh (USE_MOCK=true)
    providers.dart  state Riverpod
  features/       auth, home, search, library, player (just_audio), profile, sheets
docs/API_CONTRACT.md   peta layar → endpoint backend
tool/                  script uji langsung ke YouTube (dart run tool/yt_probe.dart "tulus")
Pendev/                mockup Pencil (acuan desain)
```

## Build rilis

```powershell
# Di laptop dengan antivirus AVG: arahkan Java ke truststore yang berisi sertifikat AVG
$env:JAVA_TOOL_OPTIONS="-Djavax.net.ssl.trustStore=C:/Users/petra/.android_jdk_trust/cacerts -Djavax.net.ssl.trustStorePassword=changeit"
flutter build apk --release --split-per-abi   # per arsitektur (lebih kecil)
flutter build apk --release                   # universal
```

APK rilis ditandatangani kunci di `android/key.properties` (tidak di-commit).
**Simpan cadangan** `C:\Users\petra\.nada\nada-release.jks` dan `android/key.properties`:
tanpa keduanya, versi baru tidak bisa meng-update aplikasi yang sudah terpasang di HP teman.
Naikkan `version` di `pubspec.yaml` (mis. `1.0.1+2`) setiap rilis baru.
