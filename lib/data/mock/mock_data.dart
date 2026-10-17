import '../models/models.dart';

/// Data contoh untuk tahap UI. Dihapus setelah backend & YouTube tersambung.
abstract final class MockData {
  static const hatiHati = Track(videoId: 'hati-hati', title: 'Hati-Hati di Jalan', artist: 'Tulus', durationS: 242);
  static const monokrom = Track(videoId: 'monokrom', title: 'Monokrom', artist: 'Tulus', durationS: 261);
  static const interaksi = Track(videoId: 'interaksi', title: 'Interaksi', artist: 'Tulus', durationS: 230);
  static const sepi = Track(videoId: 'sepi', title: 'Sepi', artist: 'Tulus', durationS: 248);
  static const ruangSendiri = Track(videoId: 'ruang-sendiri', title: 'Ruang Sendiri', artist: 'Tulus', durationS: 224);
  static const sial = Track(videoId: 'sial', title: 'Sial', artist: 'Mahalini', durationS: 228);
  static const tuturBatin = Track(videoId: 'tutur-batin', title: 'Tutur Batin', artist: 'Yura Yunita', durationS: 255);
  static const kaliKedua = Track(videoId: 'kali-kedua', title: 'Kali Kedua', artist: 'Raisa', durationS: 262);
  static const rumahKeRumah = Track(videoId: 'rumah-ke-rumah', title: 'Rumah ke Rumah', artist: 'Hindia', durationS: 288);
  static const secukupnya = Track(videoId: 'secukupnya', title: 'Secukupnya', artist: 'Hindia', durationS: 239);
  static const toTheBone = Track(videoId: 'to-the-bone', title: 'To The Bone', artist: 'Pamungkas', durationS: 222);
  static const celenganRindu = Track(videoId: 'celengan-rindu', title: 'Celengan Rindu', artist: 'Fiersa Besari', durationS: 250);
  static const rehat = Track(videoId: 'rehat', title: 'Rehat', artist: 'Kunto Aji', durationS: 245);
  static const bertaut = Track(videoId: 'bertaut', title: 'Bertaut', artist: 'Nadin Amizah', durationS: 291);
  static const fineToday = Track(videoId: 'fine-today', title: 'Fine Today', artist: 'Ardhito Pramono', durationS: 270);

  static const allTracks = [
    hatiHati, monokrom, interaksi, sepi, ruangSendiri, sial, tuturBatin, kaliKedua,
    rumahKeRumah, secukupnya, toTheBone, celenganRindu, rehat, bertaut, fineToday,
  ];

  static const user = AppUser(id: 'u1', username: 'petra');

  static final playlists = <Playlist>[
    Playlist(id: 'p1', name: 'Galau Malam', tracks: [hatiHati, monokrom, sial, tuturBatin, rumahKeRumah, bertaut, celenganRindu]),
    Playlist(id: 'p2', name: 'Kerja Fokus', tracks: [toTheBone, fineToday, secukupnya, rehat]),
    Playlist(id: 'p3', name: 'Lagu Random', tracks: [kaliKedua, interaksi, sepi, ruangSendiri, sial]),
    Playlist(id: 'p4', name: 'Road Trip', tracks: [fineToday, toTheBone, rumahKeRumah]),
  ];

  static final likes = <Track>[hatiHati, monokrom, tuturBatin, rumahKeRumah, secukupnya, celenganRindu, fineToday];

  static List<HistoryEntry> history() {
    final now = DateTime.now();
    DateTime ago(int days, int hours) => now.subtract(Duration(days: days, hours: hours));
    return [
      HistoryEntry(track: hatiHati, playedAt: ago(0, 0)),
      HistoryEntry(track: secukupnya, playedAt: ago(0, 1)),
      HistoryEntry(track: toTheBone, playedAt: ago(0, 2)),
      HistoryEntry(track: celenganRindu, playedAt: ago(1, 1)),
      HistoryEntry(track: rehat, playedAt: ago(1, 3)),
      HistoryEntry(track: monokrom, playedAt: ago(5, 2)),
      HistoryEntry(track: fineToday, playedAt: ago(5, 4)),
    ];
  }

  /// Lirik contoh (bukan lirik asli), sama seperti di mockup.
  static const lyrics = [
    LyricLine(Duration(seconds: 0), 'Ku ingat lagi tatapmu waktu itu'),
    LyricLine(Duration(seconds: 12), 'Saat ku pamit tuk pergi jauh'),
    LyricLine(Duration(seconds: 24), 'Kau bilang hati-hati di jalan'),
    LyricLine(Duration(seconds: 36), 'Jangan lupakan aku di sini'),
    LyricLine(Duration(seconds: 48), 'Walau jarak memisahkan kita'),
    LyricLine(Duration(seconds: 60), 'Rindu ini tak pernah reda'),
    LyricLine(Duration(seconds: 72), 'Sampai jumpa lagi suatu saat'),
    LyricLine(Duration(seconds: 84), 'Kan ku bawa pulang ceritaku'),
    LyricLine(Duration(seconds: 96), 'Untukmu yang setia menunggu'),
  ];
}
