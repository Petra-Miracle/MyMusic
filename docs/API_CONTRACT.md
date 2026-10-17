# Kontrak API — Nada

Acuan untuk membangun backend di `D:\Spotify-Bajakan-Backend` (Express + Prisma + Neon, deploy Vercel).
Semua method di sini sudah dipanggil oleh UI lewat interface di
`lib/data/repositories/repositories.dart`; sekarang diisi data mock (`lib/data/mock/`).
Saat backend siap, cukup buat `Api*Repository` lalu ganti 4 baris provider di `lib/data/providers.dart`.

## Aturan umum

- Base URL: `https://<nama-proyek>.vercel.app/api`
- Format: JSON. Waktu dalam ISO 8601 (`2026-10-17T21:42:00.000Z`).
- Auth: header `Authorization: Bearer <token>` untuk semua endpoint **kecuali** `/auth/login` & `/auth/register`.
- Error: status 4xx/5xx dengan body `{ "error": "Pesan yang bisa langsung ditampilkan ke user" }`.
  Aplikasi menampilkan `error` apa adanya (mis. di bawah form login).

## Bentuk data

```jsonc
// Track — primary key = videoId YouTube
{ "videoId": "dQw4w9WgXcQ", "title": "Hati-Hati di Jalan", "artist": "Tulus", "durationS": 242, "thumbnail": "https://i.ytimg.com/..." }

// User
{ "id": "clx…", "username": "petra" }

// Playlist (list & detail sama-sama berisi tracks; dipakai untuk cover kolase & jumlah lagu)
{ "id": "clx…", "name": "Galau Malam", "tracks": [Track, …] }

// HistoryEntry
{ "track": Track, "playedAt": "2026-10-17T21:42:00.000Z" }
```

> `Track` dikirim lengkap oleh aplikasi saat like / tambah ke playlist / riwayat,
> karena metadata lagu datang dari YouTube di HP. Backend cukup **upsert** ke tabel `Track`.

## Endpoint

### Auth

| Method | Path | Body | Response |
|---|---|---|---|
| POST | `/auth/login` | `{ username, password }` | `{ token, user }` · 401 `Username atau password salah` |
| POST | `/auth/register` | `{ inviteCode, username, password }` | `{ token, user }` · 400 `Kode undangan tidak valid atau sudah dipakai` · 409 `Username sudah dipakai` |
| GET | `/auth/me` | – | `{ user }` · 401 bila token tidak valid |
| POST | `/invites` | – | `{ code }` (format `NADA-XXXXX`) |

### Playlist

| Method | Path | Body | Response |
|---|---|---|---|
| GET | `/playlists` | – | `Playlist[]` (terbaru dulu) |
| GET | `/playlists/:id` | – | `Playlist` · 404 |
| POST | `/playlists` | `{ name }` | `Playlist` (tracks kosong) |
| PATCH | `/playlists/:id` | `{ name }` | `Playlist` |
| DELETE | `/playlists/:id` | – | 204 |
| POST | `/playlists/:id/tracks` | `{ track: Track }` | 204 (abaikan bila sudah ada) |
| DELETE | `/playlists/:id/tracks/:videoId` | – | 204 |

### Disukai

| Method | Path | Body | Response |
|---|---|---|---|
| GET | `/likes` | – | `Track[]` (terbaru dulu) |
| PUT | `/likes/:videoId` | `{ track: Track }` | 204 (idempoten) |
| DELETE | `/likes/:videoId` | – | 204 |

### Riwayat

| Method | Path | Body | Response |
|---|---|---|---|
| GET | `/history?limit=50` | – | `HistoryEntry[]` (terbaru dulu) |
| POST | `/history` | `{ track: Track }` | 204 |

## Peta layar → endpoint

| Layar (mockup) | Komponen / aksi | Endpoint | Method repository | File UI |
|---|---|---|---|---|
| I — Splash | cek token tersimpan | `GET /auth/me` | `AuthRepository.currentUser` | `features/auth/splash_screen.dart` |
| J — Masuk | tombol **Masuk** | `POST /auth/login` | `AuthRepository.login` | `features/auth/login_screen.dart` |
| K — Daftar | tombol **Daftar** | `POST /auth/register` | `AuthRepository.register` | `features/auth/register_screen.dart` |
| A — Beranda | grid **Baru diputar** | `GET /history` | `LibraryRepository.getHistory` | `features/home/home_screen.dart` |
| A — Beranda | **Pilihan cepat untukmu** | – (YouTube, client-side) | `MusicRepository.related` | `features/home/home_screen.dart` |
| A — Beranda | **Playlist kamu** | `GET /playlists` | `LibraryRepository.getPlaylists` | `features/home/home_screen.dart` |
| A2 — Beranda baru | tampil bila riwayat kosong | `GET /history` | `LibraryRepository.getHistory` | `features/home/home_screen.dart` |
| B — Cari | hasil, loading, tidak ditemukan | – (YouTube, client-side) | `MusicRepository.search` | `features/search/search_screen.dart` |
| B — Cari | pencarian terakhir | – (lokal di HP) | `RecentSearchesNotifier` | `data/providers.dart` |
| C — Now Playing | ikon **hati** | `PUT` / `DELETE /likes/:videoId` | `LibraryRepository.like` / `unlike` | `features/player/now_playing_screen.dart` |
| C — Now Playing | lagu mulai diputar | `POST /history` | `LibraryRepository.addHistory` | `features/player/player_controller.dart` |
| C — Now Playing | stream audio | – (YouTube, client-side) | `MusicRepository.streamUrl` | `features/player/player_controller.dart` |
| D — Lirik | lirik tersinkron | – (LRCLIB, client-side) | `LyricsRepository.getLyrics` | `features/player/lyrics_screen.dart` |
| E — Antrean | urutkan, hapus, autoplay | – (state lokal player) | `PlayerController` | `features/player/queue_sheet.dart` |
| F — Koleksi | daftar playlist | `GET /playlists` | `LibraryRepository.getPlaylists` | `features/library/library_screen.dart` |
| F — Koleksi | tombol **+** / S3 Buat playlist | `POST /playlists` | `LibraryRepository.createPlaylist` | `features/sheets/track_sheets.dart` |
| F3 — Disukai | daftar & hapus (ikon hati) | `GET /likes`, `DELETE /likes/:videoId` | `getLikes` / `unlike` | `features/library/library_screen.dart` |
| H — Riwayat | daftar per hari | `GET /history` | `LibraryRepository.getHistory` | `features/library/library_screen.dart` |
| G — Detail Playlist | isi playlist | `GET /playlists/:id` * | `LibraryRepository.getPlaylist` | `features/library/playlist_detail_screen.dart` |
| G — Detail Playlist | menu: **Ubah nama** | `PATCH /playlists/:id` | `LibraryRepository.renamePlaylist` | `features/library/playlist_detail_screen.dart` |
| G — Detail Playlist | menu: **Hapus playlist** | `DELETE /playlists/:id` | `LibraryRepository.deletePlaylist` | `features/library/playlist_detail_screen.dart` |
| S1 — Opsi lagu | **Suka / Hapus dari disukai** | `PUT` / `DELETE /likes/:videoId` | `like` / `unlike` | `features/sheets/track_sheets.dart` |
| S2 — Tambah ke playlist | centang playlist | `POST /playlists/:id/tracks` | `LibraryRepository.addToPlaylist` | `features/sheets/track_sheets.dart` |
| S2 — Tambah ke playlist | hilangkan centang | `DELETE /playlists/:id/tracks/:videoId` | `LibraryRepository.removeFromPlaylist` | `features/sheets/track_sheets.dart` |
| L — Profil | **Buat kode undangan** | `POST /invites` | `AuthRepository.createInviteCode` | `features/profile/profile_screen.dart` |
| L — Profil | **Keluar** | – (hapus token lokal) | `AuthRepository.logout` | `features/profile/profile_screen.dart` |
| L — Profil | kualitas audio, autoplay, cache | – (lokal di HP) | `SettingsNotifier` | `data/providers.dart` |

\* Saat ini Detail Playlist membaca dari hasil `GET /playlists` yang sudah ada di memori
(karena list sudah berisi tracks), jadi `GET /playlists/:id` opsional untuk versi pertama.

## Belum di backend (sengaja)

- **Search, stream, lagu serupa** → `youtube_explode_dart` langsung dari HP (lihat diskusi arsitektur: IP datacenter Vercel diblokir YouTube).
- **Lirik** → LRCLIB langsung dari HP (gratis, tanpa API key).
- **Pengaturan & pencarian terakhir** → `shared_preferences` di HP.
