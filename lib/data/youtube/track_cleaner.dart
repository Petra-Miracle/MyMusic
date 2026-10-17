/// Merapikan judul video YouTube menjadi (judul lagu, artis), dan menyaring hasil yang bukan lagu.
///
/// Contoh: "TULUS - Hati-Hati di Jalan (Official Music Video)" oleh "Tulus"
///         → ("Hati-Hati di Jalan", "Tulus").
library;

final _bracketNoise = RegExp(
  r'\s*[\(\[【][^\)\]】]*?(official|video|audio|lyric|lirik|visuali[sz]er|\bmv\b|m/v|\bhd\b|\b4k\b|remaster|explicit|clip)[^\)\]】]*[\)\]】]',
  caseSensitive: false,
);
final _artistSuffix = RegExp(r'(\s*-\s*topic|vevo|\s+official|\s+music)$', caseSensitive: false);
final _dash = RegExp(r'\s+[-–—]\s+');
final _hashtag = RegExp(r'\s*#\S+');
final _spaces = RegExp(r'\s{2,}');

/// Kata yang menandakan bukan rekaman lagu asli (kecuali memang dicari).
const _nonSongWords = [
  'karaoke', 'instrumental', 'full album', 'playlist', 'compilation', 'kompilasi', 'kumpulan lagu',
  'nonstop', 'non stop', 'medley', 'mashup', '1 hour', '1 jam', 'top 10', 'top 20', 'lagu terbaik',
  'best song', 'collection', 'tanpa iklan', 'slowed', 'reverb', 'speed up', 'sped up', 'nightcore',
  '8d audio', 'tiktok version', 'tiktok ver',
];

String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

/// "SIAL" → "Sial"; teks dengan huruf kecil dibiarkan.
String _fixAllCaps(String s) {
  if (s != s.toUpperCase() || !RegExp(r'[A-Z]{2}').hasMatch(s)) return s;
  return s.toLowerCase().replaceAllMapped(RegExp(r"(^|[\s(\-'])([a-z])"), (m) => '${m[1]}${m[2]!.toUpperCase()}');
}

String cleanArtist(String author) => author.replaceAll(_artistSuffix, '').trim();

/// Hasil pembacaan satu judul video.
class ParsedTitle {
  const ParsedTitle(this.title, this.artist, {this.pair, this.fromUploader = false});

  final String title;
  final String artist;

  /// Dua sisi "A - B" (urutan asli) bila judul memakai tanda pisah.
  final (String, String)? pair;

  /// True bila salah satu sisi cocok dengan nama channel (urutannya pasti benar).
  final bool fromUploader;
}

ParsedTitle parseTitle(String rawTitle, String author) {
  final artist = cleanArtist(author);
  var t = rawTitle.replaceAll(_bracketNoise, '').replaceAll(_hashtag, '');
  // Buang ekor seperti "| Lirik Lagu" atau "// Live at …".
  t = t.split(RegExp(r'\s+(\||//)\s*')).first;
  t = t.replaceAll(RegExp(r'''^["'“]|["'”]$'''), '').replaceAll(_spaces, ' ').trim();

  final parts = t.split(_dash);
  if (parts.length < 2) return ParsedTitle(_fixAllCaps(t.isEmpty ? rawTitle : t), artist);

  final left = _fixAllCaps(parts.first.trim());
  final right = _fixAllCaps(parts.sublist(1).join(' - ').trim());
  final a = _norm(artist);
  final l = _norm(left);
  final r = _norm(right);
  if (a.isNotEmpty && l.isNotEmpty && (l == a || a.contains(l) || l.contains(a))) {
    return ParsedTitle(right, artist, pair: (left, right), fromUploader: true);
  }
  if (a.isNotEmpty && r.isNotEmpty && (r == a || r.contains(a))) {
    return ParsedTitle(left, right, pair: (left, right), fromUploader: true);
  }
  // Tidak bisa dipastikan: anggap pola paling umum "Artis - Judul" (dikoreksi oleh [cleanTitles]).
  return ParsedTitle(right, left, pair: (left, right));
}

/// Satu judul tanpa konteks.
(String, String) cleanTitle(String rawTitle, String author) {
  final p = parseTitle(rawTitle, author);
  return (p.title, p.artist);
}

/// Banyak judul sekaligus (mis. satu halaman hasil search). Untuk judul "A - B" yang
/// urutannya ambigu, sisi artis ditentukan lewat voting dari judul lain dengan pasangan sama:
/// judul dari channel resmi bernilai 3 suara, judul lain 1 suara (sisi kiri dianggap artis).
List<(String, String)> cleanTitles(List<(String, String)> rawAndAuthor) {
  final parsed = [for (final (raw, author) in rawAndAuthor) parseTitle(raw, author)];
  // votes[pasangan][sisi] = jumlah suara bahwa sisi itu adalah artis.
  final votes = <String, Map<String, int>>{};
  String key((String, String) p) => ([_norm(p.$1), _norm(p.$2)]..sort()).join('|');
  for (final p in parsed) {
    if (p.pair == null) continue;
    final side = _norm(p.artist);
    final tally = votes.putIfAbsent(key(p.pair!), () => {});
    tally[side] = (tally[side] ?? 0) + (p.fromUploader ? 3 : 1);
  }
  return [
    for (final p in parsed)
      if (p.pair == null || p.fromUploader)
        (p.title, p.artist)
      else
        () {
          final tally = votes[key(p.pair!)]!;
          final (left, right) = p.pair!;
          final leftVotes = tally[_norm(left)] ?? 0;
          final rightVotes = tally[_norm(right)] ?? 0;
          return rightVotes > leftVotes ? (left, right) : (right, left);
        }(),
  ];
}

/// True bila judul tidak menunjukkan karaoke/kompilasi (kecuali kata itu ada di [query]).
bool titleLooksLikeSong(String title, {String query = ''}) {
  final t = title.toLowerCase();
  final q = query.toLowerCase();
  return !_nonSongWords.any((w) => t.contains(w) && !q.contains(w));
}

/// True bila durasi wajar untuk satu lagu (1–12 menit). Null = siaran langsung.
bool durationLooksLikeSong(Duration? d) =>
    d != null && d >= const Duration(minutes: 1) && d <= const Duration(minutes: 12);

bool looksLikeSong({required String title, required Duration? duration, String query = ''}) =>
    durationLooksLikeSong(duration) && titleLooksLikeSong(title, query: query);

/// True bila [title] adalah versi lain dari [original] (mis. "Separuh Aku (Live Performance)").
bool isVariantOf(String title, String original) {
  final o = _norm(original);
  return o.length >= 3 && _norm(title).contains(o);
}

/// Kunci untuk membuang duplikat (MV, lyric video, dan audio dari lagu yang sama).
String dedupeKey(String title, String artist) => '${_norm(title)}|${_norm(artist)}';
