// ignore_for_file: avoid_print
// Debug: judul mentah hasil search & related.  dart run tool/yt_raw.dart "kata kunci"
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

Future<void> main(List<String> args) async {
  final yt = YoutubeExplode();
  final res = await yt.search.search(args.join(' '));
  for (final v in res.take(10)) {
    print('S | ${v.title} | by ${v.author} | ${v.duration}');
  }
  final rel = await yt.videos.getRelatedVideos(res.first) ?? const <Video>[];
  for (final v in rel.take(20)) {
    print('R | ${v.title} | by ${v.author} | ${v.duration}');
  }
  yt.close();
}
