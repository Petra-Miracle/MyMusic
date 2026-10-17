import 'package:youtube_explode_dart/youtube_explode_dart.dart' hide SearchResult;

import '../models/models.dart';
import '../repositories/repositories.dart';
import 'track_cleaner.dart';

/// Search, lagu serupa, dan URL audio langsung dari YouTube (berjalan di HP, bukan di server).
class YoutubeMusicRepository implements MusicRepository {
  final _yt = YoutubeExplode();

  /// Cache Video untuk lagu serupa (hindari request ulang untuk video yang sama).
  final _videos = <String, Video>{};

  /// Client Apple Vision Pro: URL audionya bisa diunduh penuh tanpa PO token.
  /// Client bawaan youtube_explode 3.1.0 (androidSdkless) kini hanya melayani ±1 MB
  /// pertama lalu 403 (issue #386; mengikuti yt-dlp & PR #389/#390 yang belum di-merge).
  static const visionOsClient = YoutubeApiClient({
    'context': {
      'client': {
        'clientName': 'VISIONOS',
        'clientVersion': '1.02',
        'deviceMake': 'Apple',
        'deviceModel': 'RealityDevice17,1',
        'osName': 'visionOS',
        'osVersion': '26.5.23O471',
        'userAgent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 15_7_3) AppleWebKit/605.1.15 '
            '(KHTML, like Gecko) Version/26.0 Safari/605.1.15',
        'hl': 'en',
        'timeZone': 'UTC',
        'utcOffsetMinutes': 0,
      },
    },
  }, 'https://www.youtube.com/youtubei/v1/player?prettyPrint=false');

  static String thumbnailFor(String videoId) => 'https://i.ytimg.com/vi/$videoId/mqdefault.jpg';

  /// Video → lagu: saring, rapikan judul (dengan voting antar-hasil), buang duplikat.
  List<Track> _songs(List<Video> videos, {String query = '', Set<String>? seen}) {
    final candidates = videos.where((v) => looksLikeSong(title: v.title, duration: v.duration, query: query)).toList();
    final names = cleanTitles([for (final v in candidates) (v.title, v.author)]);
    final keys = seen ?? <String>{};
    final tracks = <Track>[];
    for (final (i, v) in candidates.indexed) {
      final (title, artist) = names[i];
      if (!keys.add(dedupeKey(title, artist))) continue;
      _videos[v.id.value] = v;
      tracks.add(Track(
        videoId: v.id.value,
        title: title,
        artist: artist,
        durationS: v.duration!.inSeconds,
        thumbnail: thumbnailFor(v.id.value),
      ));
    }
    return tracks;
  }

  @override
  Future<SearchResult> search(String query) async {
    final tracks = _songs(await _yt.search.search(query), query: query);
    // "Hasil teratas" berupa artis bila nama artis disebut di kata kunci & muncul ≥ 2 kali.
    final q = query.toLowerCase();
    final counts = <String, int>{};
    for (final t in tracks) {
      counts[t.artist] = (counts[t.artist] ?? 0) + 1;
    }
    final top = counts.entries
        .where((e) => e.value >= 2 && q.contains(e.key.toLowerCase()))
        .fold<MapEntry<String, int>?>(null, (best, e) => best == null || e.value > best.value ? e : best);
    return SearchResult(topArtist: top?.key, tracks: tracks);
  }

  @override
  Future<List<Track>> related(Track seed) async {
    // Dua sumber paralel: "video terkait" YouTube (variasi artis) + lagu lain dari artis yang sama.
    final (fromRelated, fromArtist) = await (
      _relatedVideos(seed).catchError((Object _) => <Track>[]),
      _yt.search
          .search(seed.artist)
          .then((list) => _songs(list, seen: {dedupeKey(seed.title, seed.artist)}))
          .catchError((Object _) => <Track>[]),
    ).wait;
    // Selang-seling supaya autoplay tidak melulu satu artis, lalu buang duplikat.
    final keys = {dedupeKey(seed.title, seed.artist)};
    final mixed = <Track>[];
    for (var i = 0; i < fromRelated.length || i < fromArtist.length; i++) {
      for (final t in [if (i < fromRelated.length) fromRelated[i], if (i < fromArtist.length) fromArtist[i]]) {
        // Lewati lagu yang sama dalam versi lain (live, lirik, remix…).
        if (t.videoId == seed.videoId || isVariantOf(t.title, seed.title)) continue;
        if (keys.add(dedupeKey(t.title, t.artist))) mixed.add(t);
      }
    }
    return mixed.take(15).toList();
  }

  Future<List<Track>> _relatedVideos(Track seed) async {
    final video = _videos[seed.videoId] ?? await _yt.videos.get(seed.videoId);
    final list = await _yt.videos.getRelatedVideos(video) ?? const <Video>[];
    // Daftar ini tidak menyertakan durasi: saring dari judul dulu, lalu ambil detail
    // (durasi) untuk maksimal 10 kandidat secara paralel.
    final candidates = list.where((v) => v.id != video.id && titleLooksLikeSong(v.title)).take(10);
    final detailed = await Future.wait(candidates.map((v) async {
      if (v.duration != null) return v;
      try {
        return await _yt.videos.get(v.id);
      } catch (_) {
        return null;
      }
    }));
    return _songs(detailed.nonNulls.toList());
  }

  @override
  Future<Uri> streamUrl(String videoId, {AudioQuality quality = AudioQuality.normal}) async {
    StreamManifest manifest;
    try {
      manifest = await _yt.videos.streamsClient.getManifest(videoId, ytClients: [visionOsClient]);
    } catch (_) {
      // Cadangan: client bawaan library (bisa kembali normal bila YouTube berubah lagi).
      manifest = await _yt.videos.streamsClient.getManifest(videoId);
    }
    // m4a (AAC) supaya bisa diputar di Android maupun iOS.
    final m4a = manifest.audioOnly.where((a) => a.container == StreamContainer.mp4).toList()
      ..sort((a, b) => a.bitrate.compareTo(b.bitrate));
    final pool = m4a.isNotEmpty ? m4a : (manifest.audioOnly.toList()..sort((a, b) => a.bitrate.compareTo(b.bitrate)));
    if (pool.isEmpty) throw StateError('Audio untuk lagu ini tidak tersedia');
    final chosen = quality == AudioQuality.low ? pool.first : pool.last;
    return chosen.url;
  }

  void dispose() => _yt.close();
}
