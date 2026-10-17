import '../models/models.dart';
import '../repositories/repositories.dart';
import 'api_client.dart';

typedef _Json = Map<String, dynamic>;

/// Implementasi [AuthRepository] ke backend (lihat docs/API_CONTRACT.md).
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._api);

  final ApiClient _api;

  Future<AppUser> _saveSession(_Json body) async {
    await _api.tokens.write(body['token'] as String);
    return AppUser.fromJson(body['user'] as _Json);
  }

  @override
  Future<AppUser> login(String username, String password) async =>
      _saveSession(await _api.post<_Json>('/auth/login', {'username': username, 'password': password}));

  @override
  Future<AppUser> register(String inviteCode, String username, String password) async => _saveSession(
        await _api.post<_Json>('/auth/register', {
          'inviteCode': inviteCode,
          'username': username,
          'password': password,
        }),
      );

  @override
  Future<AppUser?> currentUser() async {
    if (await _api.tokens.read() == null) return null;
    try {
      final body = await _api.get<_Json>('/auth/me');
      return AppUser.fromJson(body['user'] as _Json);
    } on ApiException catch (e) {
      // Token kedaluwarsa / tidak valid → minta login lagi. Error lain (mis. offline) diteruskan.
      if (!e.isUnauthorized) rethrow;
      await _api.tokens.clear();
      return null;
    }
  }

  @override
  Future<void> logout() => _api.tokens.clear();

  @override
  Future<String> createInviteCode() async => (await _api.post<_Json>('/invites'))['code'] as String;
}

/// Implementasi [LibraryRepository] ke backend.
class ApiLibraryRepository implements LibraryRepository {
  ApiLibraryRepository(this._api);

  final ApiClient _api;

  static String _enc(String s) => Uri.encodeComponent(s);

  @override
  Future<List<Playlist>> getPlaylists() async =>
      [for (final p in await _api.get<List<dynamic>>('/playlists')) Playlist.fromJson(p as _Json)];

  @override
  Future<Playlist> getPlaylist(String id) async => Playlist.fromJson(await _api.get<_Json>('/playlists/${_enc(id)}'));

  @override
  Future<Playlist> createPlaylist(String name) async =>
      Playlist.fromJson(await _api.post<_Json>('/playlists', {'name': name}));

  @override
  Future<void> renamePlaylist(String id, String name) => _api.patch<_Json>('/playlists/${_enc(id)}', {'name': name});

  @override
  Future<void> deletePlaylist(String id) => _api.delete('/playlists/${_enc(id)}');

  @override
  Future<void> addToPlaylist(String playlistId, Track track) =>
      _api.post<void>('/playlists/${_enc(playlistId)}/tracks', {'track': track.toJson()});

  @override
  Future<void> removeFromPlaylist(String playlistId, String videoId) =>
      _api.delete('/playlists/${_enc(playlistId)}/tracks/${_enc(videoId)}');

  @override
  Future<List<Track>> getLikes() async =>
      [for (final t in await _api.get<List<dynamic>>('/likes')) Track.fromJson(t as _Json)];

  @override
  Future<void> like(Track track) => _api.put<void>('/likes/${_enc(track.videoId)}', {'track': track.toJson()});

  @override
  Future<void> unlike(String videoId) => _api.delete('/likes/${_enc(videoId)}');

  @override
  Future<List<HistoryEntry>> getHistory() async => [
        for (final h in await _api.get<List<dynamic>>('/history', query: {'limit': 50}))
          HistoryEntry.fromJson(h as _Json),
      ];

  @override
  Future<void> addHistory(Track track) => _api.post<void>('/history', {'track': track.toJson()});
}
