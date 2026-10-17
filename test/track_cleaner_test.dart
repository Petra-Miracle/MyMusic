import 'package:flutter_test/flutter_test.dart';
import 'package:nada/data/lyrics/lrclib_lyrics_repository.dart';
import 'package:nada/data/youtube/track_cleaner.dart';

void main() {
  group('cleanTitle', () {
    final cases = <(String, String), (String, String)>{
      // (judul video, channel) → (judul lagu, artis)
      ('TULUS - Hati-Hati di Jalan (Official Music Video)', 'Tulus'): ('Hati-Hati di Jalan', 'Tulus'),
      ('TULUS - Hati-Hati di Jalan (Official Lyric Video)', 'Tulus'): ('Hati-Hati di Jalan', 'Tulus'),
      ('Mahalini - Sial [Official Music Video]', 'Mahalini'): ('Sial', 'Mahalini'),
      ('Monokrom', 'Tulus - Topic'): ('Monokrom', 'Tulus'),
      ('Hindia - Rumah ke Rumah (Official Audio)', 'Hindia'): ('Rumah ke Rumah', 'Hindia'),
      ('Pamungkas – To The Bone (Official Lyric Video)', 'Pamungkas'): ('To The Bone', 'Pamungkas'),
      ('Raisa - Kali Kedua (Live at Java Jazz)', 'RaisaVEVO'): ('Kali Kedua (Live at Java Jazz)', 'Raisa'),
      ('"Celengan Rindu"', 'Fiersa Besari'): ('Celengan Rindu', 'Fiersa Besari'),
      ('MAHALINI - SIAL #FABULA (VIDEO LIRIK) | LIRIK LAGU TERBARU', 'StarHits Music'): ('Sial', 'Mahalini'),
      ('Andai Aku Bisa - Tulus, Erwin Gutawa Orchestra', 'Tulus'): ('Andai Aku Bisa', 'Tulus, Erwin Gutawa Orchestra'),
    };
    for (final MapEntry(key: (title, author), value: expected) in cases.entries) {
      test('$title / $author', () => expect(cleanTitle(title, author), expected));
    }
  });

  test('cleanTitles: urutan ambigu ditentukan voting hasil lain', () {
    final names = cleanTitles([
      ('Sial - Mahalini ( Lirik lagu )', 'Fcknnght'),
      ('MAHALINI - SIAL #FABULA (VIDEO LIRIK)', 'StarHits Music'),
      ('Mahalini - Sial (Lyrics)', 'Lingkup Senja'),
      ('Hati-Hati di Jalan - Tulus | Lirik Lagu', 'Indolirik'),
      ('TULUS - Hati-Hati di Jalan (Official Music Video)', 'Tulus'),
    ]);
    expect(names, [
      ('Sial', 'Mahalini'),
      ('Sial', 'Mahalini'),
      ('Sial', 'Mahalini'),
      ('Hati-Hati di Jalan', 'Tulus'),
      ('Hati-Hati di Jalan', 'Tulus'),
    ]);
  });

  group('looksLikeSong', () {
    const fourMin = Duration(minutes: 4);
    test('lagu biasa lolos', () => expect(looksLikeSong(title: 'Tulus - Monokrom', duration: fourMin), isTrue));
    test('siaran langsung (tanpa durasi) ditolak', () => expect(looksLikeSong(title: 'x', duration: null), isFalse));
    test('kompilasi 1 jam ditolak', () {
      expect(looksLikeSong(title: 'TULUS - PLAYLIST 11 LAGU TERBAIK', duration: const Duration(hours: 1)), isFalse);
    });
    test('karaoke ditolak kecuali dicari', () {
      const t = 'Tulus – Hati-Hati di Jalan (Karaoke Version)';
      expect(looksLikeSong(title: t, duration: fourMin), isFalse);
      expect(looksLikeSong(title: t, duration: fourMin, query: 'tulus karaoke'), isTrue);
    });
    test('video pendek ditolak', () {
      expect(looksLikeSong(title: 'Teaser', duration: const Duration(seconds: 30)), isFalse);
    });
  });

  test('dedupeKey mengabaikan huruf besar & tanda baca', () {
    expect(dedupeKey('Hati-Hati di Jalan', 'TULUS'), dedupeKey('hati hati di jalan', 'Tulus'));
  });

  group('parseLrc', () {
    test('baris bertimestamp, baris kosong dibuang', () {
      final lines = parseLrc('[00:13.24] Baris satu\n[00:18.10]\n[01:02.5] Baris dua\nteks tanpa waktu')!;
      expect(lines.map((l) => l.text), ['Baris satu', 'Baris dua']);
      expect(lines.map((l) => l.time), [
        const Duration(milliseconds: 13240),
        const Duration(minutes: 1, seconds: 2, milliseconds: 500),
      ]);
    });
    test('kosong → null', () {
      expect(parseLrc(null), isNull);
      expect(parseLrc('  '), isNull);
    });
  });
}
