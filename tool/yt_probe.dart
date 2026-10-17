// ignore_for_file: avoid_print
// Uji langsung YoutubeMusicRepository + LrclibLyricsRepository dari komputer ini:
//   dart run tool/yt_probe.dart "kata kunci"
import 'dart:io';

import 'package:nada/data/lyrics/lrclib_lyrics_repository.dart';
import 'package:nada/data/models/models.dart';
import 'package:nada/data/youtube/youtube_music_repository.dart';

Future<void> main(List<String> args) async {
  final query = args.isEmpty ? 'tulus' : args.join(' ');
  final music = YoutubeMusicRepository();
  final lyrics = LrclibLyricsRepository();
  final sw = Stopwatch()..start();
  try {
    final result = await music.search(query);
    print('search "$query" → ${result.tracks.length} lagu, hasil teratas: ${result.topArtist} (${sw.elapsedMilliseconds} ms)');
    for (final t in result.tracks.take(8)) {
      print('  ${t.videoId} | ${t.title} — ${t.artist} | ${t.duration.inMinutes}:${(t.durationS % 60).toString().padLeft(2, '0')}');
    }
    final first = result.tracks.first;

    sw.reset();
    final related = await music.related(first);
    print('lagu serupa "${first.title}" → ${related.length} (${sw.elapsedMilliseconds} ms)');
    for (final t in related.take(5)) {
      print('  ${t.title} — ${t.artist}');
    }

    for (final q in AudioQuality.values) {
      sw.reset();
      final url = await music.streamUrl(first.videoId, quality: q);
      final client = HttpClient();
      final req = await client.getUrl(url)..headers.set(HttpHeaders.rangeHeader, 'bytes=0-32767');
      final res = await req.close();
      await res.drain<void>();
      client.close();
      print('stream ${q.name}: itag=${url.queryParameters['itag']} mime=${url.queryParameters['mime']} → HTTP ${res.statusCode} (${sw.elapsedMilliseconds} ms)');
    }

    sw.reset();
    final lines = await lyrics.getLyrics(first);
    print('lirik "${first.title}" → ${lines?.length ?? 0} baris (${sw.elapsedMilliseconds} ms)'
        '${lines == null ? '' : ', pertama di ${lines.first.time}'}');
  } finally {
    music.dispose();
  }
}
