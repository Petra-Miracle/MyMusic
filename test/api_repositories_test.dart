// Integration test ApiAuthRepository & ApiLibraryRepository terhadap backend sungguhan.
// Dilewati kecuali env NADA_TEST_API & NADA_TEST_INVITE diisi, mis.:
//   NADA_TEST_API=http://localhost:3001/api NADA_TEST_INVITE=NADA-XXXXX flutter test test/api_repositories_test.dart
// Jangan arahkan ke backend produksi: test ini membuat akun & data baru.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nada/data/api/api_client.dart';
import 'package:nada/data/api/api_repositories.dart';
import 'package:nada/data/models/models.dart';

void main() {
  final baseUrl = Platform.environment['NADA_TEST_API'];
  final invite = Platform.environment['NADA_TEST_INVITE'];
  final skip = baseUrl == null || invite == null ? 'NADA_TEST_API / NADA_TEST_INVITE belum diisi' : null;

  final tokens = MemoryTokenStore();
  final api = ApiClient(baseUrl: baseUrl ?? 'http://localhost', tokens: tokens);
  final auth = ApiAuthRepository(api);
  final library = ApiLibraryRepository(api);
  final username = 'flutter_${DateTime.now().millisecondsSinceEpoch}';
  const track = Track(
    videoId: '9II3OGZETo4',
    title: 'Hati-Hati di Jalan',
    artist: 'Tulus',
    durationS: 242,
    thumbnail: 'https://i.ytimg.com/vi/9II3OGZETo4/mqdefault.jpg',
  );

  test('alur lengkap: daftar → koleksi → keluar', () async {
    // Auth
    final user = await auth.register(invite!, username, 'rahasia123');
    expect(user.username, username);
    expect(await tokens.read(), isNotNull);
    expect((await auth.currentUser())?.id, user.id);
    expect(await auth.createInviteCode(), matches(RegExp(r'^NADA-[A-Z0-9]{5}$')));

    // Playlist
    final p = await library.createPlaylist('Galau Malam');
    await library.addToPlaylist(p.id, track);
    await library.addToPlaylist(p.id, track); // duplikat diabaikan
    var list = await library.getPlaylists();
    expect(list.single.tracks.single.title, 'Hati-Hati di Jalan');
    expect(list.single.tracks.single.thumbnail, track.thumbnail);
    await library.renamePlaylist(p.id, 'Lagu Hujan');
    expect((await library.getPlaylist(p.id)).name, 'Lagu Hujan');
    await library.removeFromPlaylist(p.id, track.videoId);
    expect((await library.getPlaylist(p.id)).tracks, isEmpty);
    await library.deletePlaylist(p.id);
    expect(await library.getPlaylists(), isEmpty);

    // Disukai
    await library.like(track);
    expect((await library.getLikes()).single, track);
    await library.unlike(track.videoId);
    expect(await library.getLikes(), isEmpty);

    // Riwayat
    await library.addHistory(track);
    final history = await library.getHistory();
    expect(history.single.track, track);
    expect(DateTime.now().difference(history.single.playedAt).inMinutes, lessThan(5));

    // Error dari server diteruskan apa adanya
    await expectLater(
      library.createPlaylist('   '),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Nama playlist wajib diisi')),
    );

    // Keluar
    await auth.logout();
    expect(await auth.currentUser(), isNull);
    await expectLater(
      auth.login(username, 'salah'),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Username atau password salah')),
    );
    expect((await auth.login(username.toUpperCase(), 'rahasia123')).id, user.id);
  }, skip: skip);

  test('token tidak valid → currentUser null & token dihapus', () async {
    await tokens.write('token.palsu.sekali');
    expect(await auth.currentUser(), isNull);
    expect(await tokens.read(), isNull);
  }, skip: skip);

  test('server mati → pesan koneksi yang ramah', () async {
    final dead = ApiAuthRepository(ApiClient(baseUrl: 'http://127.0.0.1:9/api', tokens: MemoryTokenStore()));
    await expectLater(
      dead.login('a', 'b'),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Tidak ada koneksi internet')),
    );
  });
}
