// ignore_for_file: avoid_print
// Uji ukuran range yang diterima googlevideo.  dart run tool/yt_range_probe.dart [videoId]
import 'dart:io';

import 'package:youtube_explode_dart/youtube_explode_dart.dart';

Future<String> get(Uri url, String range) async {
  final c = HttpClient();
  try {
    final req = await c.getUrl(url)..headers.set(HttpHeaders.rangeHeader, range);
    final res = await req.close();
    final n = await res.fold<int>(0, (s, b) => s + b.length);
    return '${res.statusCode}/${n}B';
  } finally {
    c.close(force: true);
  }
}

Future<void> main(List<String> args) async {
  final id = args.isEmpty ? '9II3OGZETo4' : args.first;
  final yt = YoutubeExplode();
  final m = await yt.videos.streamsClient.getManifest(id);
  final a = m.audioOnly.where((s) => s.container == StreamContainer.mp4).withHighestBitrate();
  final total = a.size.totalBytes;
  print('itag ${a.tag}, total $total B, url param range? ${a.url.queryParameters.containsKey('range')}');
  for (final r in ['bytes=0-65535', 'bytes=0-1048575', 'bytes=0-${total - 1}', 'bytes=0-', 'bytes=1048576-2097151']) {
    print('$r → ${await get(a.url, r)}');
  }
  // Tanpa header Range, tapi range lewat query parameter (cara web player).
  final q = a.url.replace(queryParameters: {...a.url.queryParameters, 'range': '0-1048575'});
  final c = HttpClient();
  final res = await (await c.getUrl(q)).close();
  print('query range=0-1048575 → ${res.statusCode}/${await res.fold<int>(0, (s, b) => s + b.length)}B');
  c.close(force: true);
  yt.close();
}
