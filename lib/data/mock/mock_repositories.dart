import 'dart:math';

import '../models/models.dart';
import '../repositories/repositories.dart';
import 'mock_data.dart';

/// Simulasi latensi jaringan supaya state loading ikut teruji.
Future<void> _latency([int ms = 500]) => Future.delayed(Duration(milliseconds: ms));

class MockAuthRepository implements AuthRepository {
  AppUser? _user;

  @override
  Future<AppUser> login(String username, String password) async {
    await _latency(700);
    // Akun demo: password apa pun minimal 4 karakter, kecuali "salah".
    if (username.trim().isEmpty || password.length < 4 || password == 'salah') {
      throw const AuthException('Username atau password salah');
    }
    return _user = AppUser(id: 'u1', username: username.trim());
  }

  @override
  Future<AppUser> register(String inviteCode, String username, String password) async {
    await _latency(700);
    if (!RegExp(r'^NADA-[A-Z0-9]{4,5}$').hasMatch(inviteCode.trim().toUpperCase())) {
      throw const AuthException('Kode undangan tidak valid atau sudah dipakai');
    }
    return _user = AppUser(id: 'u2', username: username.trim());
  }

  @override
  Future<AppUser?> currentUser() async {
    await _latency(900);
    return _user;
  }

  @override
  Future<void> logout() async => _user = null;

  @override
  Future<String> createInviteCode() async {
    await _latency(400);
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random();
    return 'NADA-${List.generate(5, (_) => chars[r.nextInt(chars.length)]).join()}';
  }
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

class MockLibraryRepository implements LibraryRepository {
  final _playlists = [...MockData.playlists];
  final _likes = [...MockData.likes];
  final _history = MockData.history();
  var _nextId = 100;

  @override
  Future<List<Playlist>> getPlaylists() async {
    await _latency(300);
    return List.unmodifiable(_playlists);
  }

  @override
  Future<Playlist> getPlaylist(String id) async {
    await _latency(300);
    return _playlists.firstWhere((p) => p.id == id);
  }

  @override
  Future<Playlist> createPlaylist(String name) async {
    await _latency(300);
    final p = Playlist(id: 'p${_nextId++}', name: name, tracks: const []);
    _playlists.insert(0, p);
    return p;
  }

  @override
  Future<void> renamePlaylist(String id, String name) async {
    await _latency(200);
    final i = _playlists.indexWhere((p) => p.id == id);
    _playlists[i] = _playlists[i].copyWith(name: name);
  }

  @override
  Future<void> deletePlaylist(String id) async {
    await _latency(200);
    _playlists.removeWhere((p) => p.id == id);
  }

  @override
  Future<void> addToPlaylist(String playlistId, Track track) async {
    await _latency(200);
    final i = _playlists.indexWhere((p) => p.id == playlistId);
    final p = _playlists[i];
    if (!p.tracks.contains(track)) _playlists[i] = p.copyWith(tracks: [...p.tracks, track]);
  }

  @override
  Future<void> removeFromPlaylist(String playlistId, String videoId) async {
    await _latency(200);
    final i = _playlists.indexWhere((p) => p.id == playlistId);
    final p = _playlists[i];
    _playlists[i] = p.copyWith(tracks: p.tracks.where((t) => t.videoId != videoId).toList());
  }

  @override
  Future<List<Track>> getLikes() async {
    await _latency(300);
    return List.unmodifiable(_likes);
  }

  @override
  Future<void> like(Track track) async {
    if (!_likes.contains(track)) _likes.insert(0, track);
  }

  @override
  Future<void> unlike(String videoId) async => _likes.removeWhere((t) => t.videoId == videoId);

  @override
  Future<List<HistoryEntry>> getHistory() async {
    await _latency(300);
    return List.unmodifiable(_history);
  }

  @override
  Future<void> addHistory(Track track) async =>
      _history.insert(0, HistoryEntry(track: track, playedAt: DateTime.now()));
}

class MockMusicRepository implements MusicRepository {
  @override
  Future<SearchResult> search(String query) async {
    await _latency(900);
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const SearchResult(tracks: []);
    final tracks = MockData.allTracks
        .where((t) => t.title.toLowerCase().contains(q) || t.artist.toLowerCase().contains(q))
        .toList();
    final artist = tracks
        .map((t) => t.artist)
        .where((a) => a.toLowerCase().contains(q))
        .firstOrNull;
    return SearchResult(topArtist: artist, tracks: tracks);
  }

  @override
  Future<List<Track>> related(Track seed) async {
    await _latency(400);
    return MockData.allTracks.where((t) => t != seed).take(8).toList();
  }

  @override
  Future<Uri> streamUrl(String videoId) async => Uri.parse('mock://$videoId');
}

class MockLyricsRepository implements LyricsRepository {
  @override
  Future<List<LyricLine>?> getLyrics(Track track) async {
    await _latency(400);
    // Hanya lagu "Hati-Hati di Jalan" yang punya lirik di mock (sisanya: tidak tersedia).
    return track == MockData.hatiHati ? MockData.lyrics : null;
  }
}
