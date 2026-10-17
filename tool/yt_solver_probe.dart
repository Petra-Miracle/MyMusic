// ignore_for_file: avoid_print, implementation_imports
// Uji client "safari" + JS challenge solver (Node.js sebagai mesin JS) dari laptop.
//   dart run tool/yt_solver_probe.dart [videoId]
import 'dart:io';

import 'package:youtube_explode_dart/src/reverse_engineering/challenges/ejs/base_ejs_solver.dart';
import 'package:youtube_explode_dart/src/reverse_engineering/challenges/ejs/ejs.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class NodeEJSSolver extends BaseEJSSolver {
  NodeEJSSolver(this._modules);
  final String _modules;

  @override
  Future<String> executeJavaScript(String jsCode) async {
    final dir = await Directory.systemTemp.createTemp('ejs_node_');
    final f = File('${dir.path}/run.js');
    await f.writeAsString('$_modules\nprocess.stdout.write($jsCode);');
    final r = await Process.run('node', [f.path]);
    await dir.delete(recursive: true);
    if (r.exitCode != 0) throw Exception('node: ${r.stderr}');
    return r.stdout as String;
  }
}

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
  final sw = Stopwatch()..start();
  final modules = await EJSBuilder.getJSModules();
  print('modul EJS: ${modules.length} karakter (${sw.elapsedMilliseconds} ms)');
  final yt = YoutubeExplode(jsSolver: NodeEJSSolver(modules));
  for (final clients in [
    [YoutubeApiClient.safari],
    [YoutubeApiClient.tv],
    [YoutubeApiClient.androidVr],
  ]) {
    sw.reset();
    try {
      final m = await yt.videos.streamsClient.getManifest(id, ytClients: clients);
      final audio = m.audioOnly.toList()..sort((a, b) => b.bitrate.compareTo(a.bitrate));
      print('${clients.first.payload['context']?['client']?['clientName']}: ${audio.length} audio (${sw.elapsedMilliseconds} ms)');
      for (final a in audio.where((a) => a.container == StreamContainer.mp4).take(1)) {
        final total = a.size.totalBytes;
        print('  itag ${a.tag} ${a.bitrate.kiloBitsPerSecond.round()}kbps: '
            '0-1MB ${await get(a.url, 'bytes=0-1048575')} | 1-2MB ${await get(a.url, 'bytes=1048576-2097151')} | '
            'penuh ${await get(a.url, 'bytes=0-${total - 1}')}');
      }
    } catch (e) {
      print('${clients.first.payload['context']?['client']?['clientName']}: GAGAL ${e.toString().split('\n').first}');
    }
  }
  yt.close();
}
