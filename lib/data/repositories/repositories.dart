import '../models/models.dart';

/// Kontrak data aplikasi.
///
/// Ada dua sumber data:
/// - **Backend** (Express + Prisma di Vercel): auth, playlist, like, riwayat, undangan.
///   Komentar `→ METHOD /path` menunjukkan endpoint yang akan dipanggil.
/// - **Client-side** (langsung dari HP, tanpa backend): search & stream YouTube,
///   lirik dari LRCLIB, pengaturan lokal.
///
/// Implementasi: `data/api/` (backend), `data/youtube/`, `data/lyrics/`, dan `data/mock/`
/// (data contoh, aktif dengan `--dart-define=USE_MOCK=true`). Dipilih di `data/providers.dart`.
///
/// Peta lengkap layar → endpoint ada di `docs/API_CONTRACT.md`.

abstract interface class AuthRepository {
  /// → POST /auth/login  { username, password } → { token, user }
  Future<AppUser> login(String username, String password);

  /// → POST /auth/register  { inviteCode, username, password } → { token, user }
  Future<AppUser> register(String inviteCode, String username, String password);

  /// → GET /auth/me  (dipanggil di Splash untuk cek token yang tersimpan)
  Future<AppUser?> currentUser();

  /// Lokal saja: hapus token dari secure storage.
  Future<void> logout();

  /// → POST /invites  → { code }
  Future<String> createInviteCode();
}

abstract interface class LibraryRepository {
  /// → GET /playlists
  Future<List<Playlist>> getPlaylists();

  /// → GET /playlists/:id  (berisi daftar lagu)
  Future<Playlist> getPlaylist(String id);

  /// → POST /playlists  { name }
  Future<Playlist> createPlaylist(String name);

  /// → PATCH /playlists/:id  { name }
  Future<void> renamePlaylist(String id, String name);

  /// → DELETE /playlists/:id
  Future<void> deletePlaylist(String id);

  /// → POST /playlists/:id/tracks  { track }  (backend upsert ke tabel Track)
  Future<void> addToPlaylist(String playlistId, Track track);

  /// → DELETE /playlists/:id/tracks/:videoId
  Future<void> removeFromPlaylist(String playlistId, String videoId);

  /// → GET /likes
  Future<List<Track>> getLikes();

  /// → PUT /likes/:videoId  { track }
  Future<void> like(Track track);

  /// → DELETE /likes/:videoId
  Future<void> unlike(String videoId);

  /// → GET /history?limit=50
  Future<List<HistoryEntry>> getHistory();

  /// → POST /history  { track }  (dipanggil saat lagu mulai diputar)
  Future<void> addHistory(Track track);
}

/// Client-side: `youtube_explode_dart` dipanggil langsung dari HP.
abstract interface class MusicRepository {
  Future<SearchResult> search(String query);

  /// Lagu serupa untuk "Pilihan cepat untukmu" & autoplay.
  Future<List<Track>> related(Track seed);

  /// URL audio (m4a) untuk diputar `just_audio`. Berlaku ±6 jam.
  Future<Uri> streamUrl(String videoId, {AudioQuality quality = AudioQuality.normal});
}

/// Client-side: LRCLIB (gratis, tanpa API key).
abstract interface class LyricsRepository {
  /// Null = lirik tidak tersedia.
  Future<List<LyricLine>?> getLyrics(Track track);
}
