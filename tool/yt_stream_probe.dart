// ignore_for_file: avoid_print
// Cari kombinasi client YouTube yang URL audionya bisa diputar penuh.
//   dart run tool/yt_stream_probe.dart [videoId]
import 'dart:io';

import 'package:youtube_explode_dart/youtube_explode_dart.dart';

Future<(int, int)> fetch(Uri url, {String? ua, String range = 'bytes=0-', int maxBytes = 3 << 20}) async {
  final c = HttpClient();
  if (ua != null) c.userAgent = ua;
  try {
    final req = await c.getUrl(url)..headers.set(HttpHeaders.rangeHeader, range);
    final res = await req.close();
    var n = 0;
    await for (final chunk in res) {
      n += chunk.length;
      if (n >= maxBytes) break;
    }
    return (res.statusCode, n);
  } finally {
    c.close(force: true);
  }
}

Future<void> main(List<String> args) async {
  final id = args.isEmpty ? 'EhYlcz_aEok' : args.first;
  final yt = YoutubeExplode();
  final clients = {
    'androidSdkless(default)': [YoutubeApiClient.androidSdkless],
    'androidVr': [YoutubeApiClient.androidVr],
    'android': [YoutubeApiClient.android],
    'tv': [YoutubeApiClient.tv],
    'safari': [YoutubeApiClient.safari],
    'mweb': [YoutubeApiClient.mweb],
  };
  const exoUa = 'ExoPlayerLib/1.4.1 (Linux; Android 15) AndroidXMedia3/1.4.1';
  for (final MapEntry(key: name, value: c) in clients.entries) {
    try {
      final m = await yt.videos.streamsClient.getManifest(id, ytClients: c);
      final a = m.audioOnly.where((s) => s.container == StreamContainer.mp4).withHighestBitrate();
      final dart = await fetch(a.url);
      final exo = await fetch(a.url, ua: exoUa);
      final tail = await fetch(a.url, ua: exoUa, range: 'bytes=${a.size.totalBytes - 100000}-');
      print('$name: itag ${a.tag} | dart ${dart.$1}/${dart.$2}B | exoUA ${exo.$1}/${exo.$2}B | exoUA ekor ${tail.$1}');
    } catch (e) {
      print('$name: GAGAL ${e.toString().split('\n').first}');
    }
  }
  yt.close();
}
