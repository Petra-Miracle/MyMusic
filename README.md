# Nada

Aplikasi pemutar musik pribadi (Flutter). Lagu dicari & diputar langsung dari YouTube di HP;
backend (Express + Prisma + Neon di Vercel) hanya menyimpan akun, playlist, like, dan riwayat.

Status: **tahap UI** — semua layar dari mockup sudah jadi dan memakai data contoh (mock).

## Menjalankan

```bash
flutter pub get
flutter run -d chrome        # preview cepat di browser
flutter run                  # di HP Android (USB debugging) / emulator
```

Akun demo (mock): username apa saja, password minimal 4 karakter (password `salah` untuk melihat state error).
Kode undangan demo: format `NADA-XXXXX`, mis. `NADA-7XK2Q`.

## Struktur

```
lib/
  app/            theme (token warna/tipografi dari mockup) & router
  core/widgets/   komponen design system: TrackTile, MiniPlayer, BottomNav, Chip, Button, Sheet, Toast…
  data/
    models/       Track, Playlist, HistoryEntry, AppUser (sama dengan schema Prisma)
    repositories/ kontrak data — setiap method diberi komentar endpoint API
    mock/         data & repository contoh (dihapus setelah backend siap)
    providers.dart  state Riverpod + titik ganti Mock → Api
  features/       auth, home, search, library, player, profile, sheets
docs/API_CONTRACT.md   peta layar → endpoint untuk membangun backend
Pendev/                mockup Pencil (acuan desain)
```

## Langkah berikutnya

1. Backend di `D:\Spotify-Bajakan-Backend` mengikuti `docs/API_CONTRACT.md`.
2. `Api*Repository` (dio + token di `flutter_secure_storage`) menggantikan mock.
3. `youtube_explode_dart` + `just_audio` + `audio_service` untuk search & pemutaran asli.
