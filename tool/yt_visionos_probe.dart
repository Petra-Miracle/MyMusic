// ignore_for_file: avoid_print
// Uji client VISIONOS: apakah audio bisa diunduh penuh.  dart run tool/yt_visionos_probe.dart [id...]
import 'dart:io';

import 'package:nada/data/youtube/youtube_music_repository.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

Future<String> get(Uri url, String range, {String? ua}) async {
  final c = HttpClient();
  if (ua != null) c.userAgent = ua;
  try {
    final req = await c.getUrl(url)..headers.set(HttpHeaders.rangeHeader, range);
    final res = await req.close();
    final n = await res.fold<int>(0, (s, b) => s + b.length);
    return '${res.statusCode}/${(n / 1024).round()}KB';
  } finally {
    c.close(force: true);
  }
}

Future<void> main(List<String> args) async {
  final ids = args.isEmpty ? ['9II3OGZETo4', 'EhYlcz_aEok', 'gsjztA24jrc'] : args;
  final yt = YoutubeExplode();
  const exo = 'ExoPlayerLib/1.4.1 (Linux; Android 15) AndroidXMedia3/1.4.1';
  for (final id in ids) {
    final sw = Stopwatch()..start();
    try {
      final m = await yt.videos.streamsClient.getManifest(id, ytClients: [YoutubeMusicRepository.visionOsClient]);
      final a = m.audioOnly.where((s) => s.container == StreamContainer.mp4).withHighestBitrate();
      final t = a.size.totalBytes;
      print('$id: itag ${a.tag} ${(t / 1024 / 1024).toStringAsFixed(1)}MB manifest ${sw.elapsedMilliseconds}ms | '
          'bytes=0- exoUA ${await get(a.url, 'bytes=0-', ua: exo)} | ekor ${await get(a.url, 'bytes=${t - 200000}-${t - 1}', ua: exo)}');
    } catch (e) {
      print('$id: GAGAL ${e.toString().split('\n').first}');
    }
  }
  yt.close();
}
