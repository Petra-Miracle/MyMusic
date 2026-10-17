import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'mock/mock_repositories.dart';
import 'models/models.dart';
import 'repositories/repositories.dart';

// ---------------------------------------------------------------------------
// Repository — ganti Mock* dengan Api* saat backend siap.
// ---------------------------------------------------------------------------

final authRepositoryProvider = Provider<AuthRepository>((ref) => MockAuthRepository());
final libraryRepositoryProvider = Provider<LibraryRepository>((ref) => MockLibraryRepository());
final musicRepositoryProvider = Provider<MusicRepository>((ref) => MockMusicRepository());
final lyricsRepositoryProvider = Provider<LyricsRepository>((ref) => MockLyricsRepository());

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

// ---------------------------------------------------------------------------
// Koleksi (backend)
// ---------------------------------------------------------------------------

final playlistsProvider = AsyncNotifierProvider<PlaylistsNotifier, List<Playlist>>(PlaylistsNotifier.new);

class PlaylistsNotifier extends AsyncNotifier<List<Playlist>> {
  LibraryRepository get _repo => ref.read(libraryRepositoryProvider);

  @override
  Future<List<Playlist>> build() => _repo.getPlaylists();

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
  Future<List<Track>> build() => _repo.getLikes();

  bool isLiked(Track t) => state.value?.contains(t) ?? false;

  /// Optimistic update: UI langsung berubah, request menyusul.
  Future<void> toggle(Track t) async {
    final current = state.value ?? const <Track>[];
    if (current.contains(t)) {
      state = AsyncData(current.where((x) => x != t).toList());
      await _repo.unlike(t.videoId);
    } else {
      state = AsyncData([t, ...current]);
      await _repo.like(t);
    }
  }
}

final historyProvider = FutureProvider<List<HistoryEntry>>(
  (ref) => ref.read(libraryRepositoryProvider).getHistory(),
);

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

/// Disimpan lokal di HP (nanti pakai shared_preferences), tidak perlu backend.
final recentSearchesProvider = NotifierProvider<RecentSearchesNotifier, List<String>>(RecentSearchesNotifier.new);

class RecentSearchesNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => ['Tulus', 'Lagu galau', 'Mahalini', 'Playlist kerja'];

  void add(String q) => state = [q, ...state.where((x) => x.toLowerCase() != q.toLowerCase())].take(10).toList();

  void remove(String q) => state = state.where((x) => x != q).toList();
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
  @override
  Settings build() => const Settings();

  void setQuality(AudioQuality q) => state = state.copyWith(quality: q);
  void setAutoplay(bool v) => state = state.copyWith(autoplay: v);
}
