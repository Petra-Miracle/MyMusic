import 'package:dio/dio.dart';

import '../models/models.dart';
import '../repositories/repositories.dart';

/// Lirik tersinkron dari LRCLIB (https://lrclib.net) — gratis, tanpa API key.
class LrclibLyricsRepository implements LyricsRepository {
  final _dio = Dio(BaseOptions(
    baseUrl: 'https://lrclib.net/api',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'User-Agent': 'Nada/1.0 (aplikasi musik pribadi)'},
  ));

  @override
  Future<List<LyricLine>?> getLyrics(Track track) async {
    // 1) Cocok persis (durasi video YouTube bisa beda beberapa detik dari audio aslinya).
    try {
      final res = await _dio.get<Map<String, dynamic>>('/get', queryParameters: {
        'artist_name': track.artist,
        'track_name': track.title,
        'duration': track.durationS,
      });
      final lines = parseLrc(res.data?['syncedLyrics'] as String?);
      if (lines != null) return lines;
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) rethrow;
    }
    // 2) Pencarian bebas, ambil yang punya lirik tersinkron dengan durasi terdekat.
    final res = await _dio.get<List<dynamic>>('/search', queryParameters: {
      'track_name': track.title,
      'artist_name': track.artist,
    });
    final candidates = (res.data ?? const [])
        .cast<Map<String, dynamic>>()
        .where((c) => (c['syncedLyrics'] as String?)?.isNotEmpty ?? false)
        .toList()
      ..sort((a, b) => ((a['duration'] as num) - track.durationS).abs().compareTo(((b['duration'] as num) - track.durationS).abs()));
    return candidates.isEmpty ? null : parseLrc(candidates.first['syncedLyrics'] as String?);
  }
}

final _lrcLine = RegExp(r'^\[(\d+):(\d+(?:\.\d+)?)\]\s?(.*)$');

/// Format LRC: "[01:02.34] teks". Baris kosong (jeda musik) dibuang.
List<LyricLine>? parseLrc(String? lrc) {
  if (lrc == null || lrc.trim().isEmpty) return null;
  final lines = <LyricLine>[];
  for (final raw in lrc.split('\n')) {
    final m = _lrcLine.firstMatch(raw.trim());
    if (m == null || m.group(3)!.trim().isEmpty) continue;
    final ms = (int.parse(m.group(1)!) * 60000 + double.parse(m.group(2)!) * 1000).round();
    lines.add(LyricLine(Duration(milliseconds: ms), m.group(3)!.trim()));
  }
  return lines.isEmpty ? null : lines;
}
