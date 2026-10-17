import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/config.dart';
import 'api/api_client.dart';
import 'api/api_repositories.dart';
import 'lyrics/lrclib_lyrics_repository.dart';
import 'mock/mock_repositories.dart';
import 'models/models.dart';
import 'repositories/repositories.dart';
import 'youtube/youtube_music_repository.dart';

// ---------------------------------------------------------------------------
// Repository — data asli, atau data contoh bila `--dart-define=USE_MOCK=true`.
// ---------------------------------------------------------------------------

/// Diisi di `main()` lewat override (dibaca sekali saat aplikasi mulai).
final sharedPrefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(baseUrl: AppConfig.apiBaseUrl, tokens: SecureTokenStore()),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AppConfig.useMock ? MockAuthRepository() : ApiAuthRepository(ref.watch(apiClientProvider)),
);
final libraryRepositoryProvider = Provider<LibraryRepository>(
  (ref) => AppConfig.useMock ? MockLibraryRepository() : ApiLibraryRepository(ref.watch(apiClientProvider)),
);
final musicRepositoryProvider = Provider<MusicRepository>((ref) {
  if (AppConfig.useMock) return MockMusicRepository();
  final repo = YoutubeMusicRepository();
  ref.onDispose(repo.dispose);
  return repo;
});
final lyricsRepositoryProvider = Provider<LyricsRepository>(
  (ref) => AppConfig.useMock ? MockLyricsRepository() : LrclibLyricsRepository(),
);

// ---------------------------------------------------------------------------
// Auth
// ---------------------------------------------------------------------------

final authProvider = AsyncNotifierProvider<AuthNotifier, AppUser?>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<AppUser?> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  Future<AppUser?> build() => _repo.currentUser();

  /// Melempar [AuthException] bila gagal, supaya form bisa menampilkan error.
  Future<void> login(String username, String password) async {
    state = AsyncData(await _repo.login(username, password));
  }

  Future<void> register(String code, String username, String password) async {
    state = AsyncData(await _repo.register(code, username, password));
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AsyncData(null);
  }
}

/// ID user yang sedang login (null = belum login). Data koleksi bergantung pada ini.
final _userIdProvider = Provider<String?>((ref) => ref.watch(authProvider).value?.id);

// ---------------------------------------------------------------------------
// Koleksi (backend)
// ---------------------------------------------------------------------------

final playlistsProvider = AsyncNotifierProvider<PlaylistsNotifier, List<Playlist>>(PlaylistsNotifier.new);

class PlaylistsNotifier extends AsyncNotifier<List<Playlist>> {
  LibraryRepository get _repo => ref.read(libraryRepositoryProvider);

  @override
  Future<List<Playlist>> build() async {
    // Muat ulang saat ganti akun / logout.
    if (ref.watch(_userIdProvider) == null) return const [];
    return _repo.getPlaylists();
  }

  Future<void> _reload() async => state = AsyncData(await _repo.getPlaylists());

  Future<Playlist> create(String name) async {
    final p = await _repo.createPlaylist(name);
    await _reload();
    return p;
  }

  Future<void> rename(String id, String name) async {
    await _repo.renamePlaylist(id, name);
    await _reload();
  }

  Future<void> delete(String id) async {
    await _repo.deletePlaylist(id);
    await _reload();
  }

  Future<void> add(String playlistId, Track track) async {
    await _repo.addToPlaylist(playlistId, track);
    await _reload();
  }

  Future<void> remove(String playlistId, String videoId) async {
    await _repo.removeFromPlaylist(playlistId, videoId);
    await _reload();
  }
}

final playlistProvider = Provider.family<AsyncValue<Playlist?>, String>((ref, id) {
  return ref.watch(playlistsProvider).whenData(
        (list) => list.where((p) => p.id == id).firstOrNull,
      );
});

final likesProvider = AsyncNotifierProvider<LikesNotifier, List<Track>>(LikesNotifier.new);

class LikesNotifier extends AsyncNotifier<List<Track>> {
  LibraryRepository get _repo => ref.read(libraryRepositoryProvider);

  @override
  Future<List<Track>> build() async {
    if (ref.watch(_userIdProvider) == null) return const [];
    return _repo.getLikes();
  }

  bool isLiked(Track t) => state.value?.contains(t) ?? false;

  /// Optimistic update: UI langsung berubah, request menyusul.
  /// Bila request gagal, tampilan dikembalikan dan hasilnya `false`.
  Future<bool> toggle(Track t) async {
    final before = state.value ?? const <Track>[];
    final liked = before.contains(t);
    state = AsyncData(liked ? before.where((x) => x != t).toList() : [t, ...before]);
    try {
      liked ? await _repo.unlike(t.videoId) : await _repo.like(t);
      return true;
    } catch (_) {
      state = AsyncData(before);
      return false;
    }
  }
}

final historyProvider = FutureProvider<List<HistoryEntry>>((ref) async {
  if (ref.watch(_userIdProvider) == null) return const [];
  return ref.read(libraryRepositoryProvider).getHistory();
});

/// "Baru diputar" di Beranda: 6 lagu unik terakhir dari riwayat.
final recentlyPlayedProvider = Provider<AsyncValue<List<Track>>>((ref) {
  return ref.watch(historyProvider).whenData((h) {
    final seen = <Track>{};
    return [for (final e in h) if (seen.add(e.track)) e.track].take(6).toList();
  });
});

/// "Pilihan cepat untukmu": lagu serupa dari lagu terakhir yang diputar (client-side).
final quickPicksProvider = FutureProvider<List<Track>>((ref) async {
  final recent = await ref.watch(historyProvider.future);
  if (recent.isEmpty) return const [];
  final related = await ref.read(musicRepositoryProvider).related(recent.first.track);
  return related.take(4).toList();
});

// ---------------------------------------------------------------------------
// Pencarian (client-side)
// ---------------------------------------------------------------------------

/// Null = belum mencari (tampilkan pencarian terakhir + genre).
final searchProvider = NotifierProvider<SearchNotifier, AsyncValue<SearchResult>?>(SearchNotifier.new);

class SearchNotifier extends Notifier<AsyncValue<SearchResult>?> {
  var _requestId = 0;

  /// Kata kunci terakhir (dipakai untuk sinkron isi kolom pencarian).
  String query = '';

  @override
  AsyncValue<SearchResult>? build() => null;

  Future<void> search(String text) async {
    final q = text.trim();
    if (q.isEmpty) return clear();
    query = q;
    final id = ++_requestId;
    state = const AsyncLoading();
    ref.read(recentSearchesProvider.notifier).add(q);
    final result = await AsyncValue.guard(() => ref.read(musicRepositoryProvider).search(q));
    if (id == _requestId) state = result;
  }

  void clear() {
    _requestId++;
    query = '';
    state = null;
  }
}

/// Disimpan lokal di HP, tidak perlu backend.
final recentSearchesProvider = NotifierProvider<RecentSearchesNotifier, List<String>>(RecentSearchesNotifier.new);

class RecentSearchesNotifier extends Notifier<List<String>> {
  static const _key = 'recent_searches';

  SharedPreferences get _prefs => ref.read(sharedPrefsProvider);

  @override
  List<String> build() => _prefs.getStringList(_key) ?? const [];

  void _save(List<String> list) {
    state = list;
    _prefs.setStringList(_key, list);
  }

  void add(String q) => _save([q, ...state.where((x) => x.toLowerCase() != q.toLowerCase())].take(10).toList());

  void remove(String q) => _save(state.where((x) => x != q).toList());
}

final lyricsProvider = FutureProvider.family<List<LyricLine>?, Track>(
  (ref, track) => ref.read(lyricsRepositoryProvider).getLyrics(track),
);

// ---------------------------------------------------------------------------
// Pengaturan (lokal)
// ---------------------------------------------------------------------------

class Settings {
  const Settings({this.quality = AudioQuality.normal, this.autoplay = true});
  final AudioQuality quality;
  final bool autoplay;
  Settings copyWith({AudioQuality? quality, bool? autoplay}) =>
      Settings(quality: quality ?? this.quality, autoplay: autoplay ?? this.autoplay);
}

final settingsProvider = NotifierProvider<SettingsNotifier, Settings>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<Settings> {
  static const _qualityKey = 'audio_quality';
  static const _autoplayKey = 'autoplay';

  SharedPreferences get _prefs => ref.read(sharedPrefsProvider);

  @override
  Settings build() => Settings(
        quality: AudioQuality.values.asNameMap()[_prefs.getString(_qualityKey)] ?? AudioQuality.normal,
        autoplay: _prefs.getBool(_autoplayKey) ?? true,
      );

  void setQuality(AudioQuality q) {
    state = state.copyWith(quality: q);
    _prefs.setString(_qualityKey, q.name);
  }

  void setAutoplay(bool v) {
    state = state.copyWith(autoplay: v);
    _prefs.setBool(_autoplayKey, v);
  }
}
