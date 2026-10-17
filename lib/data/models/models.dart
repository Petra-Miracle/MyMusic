// Model data aplikasi. Field-nya mengikuti schema Prisma di backend
// (`Track`, `Playlist`, `Like`, `History`, `User`), sehingga `fromJson`
// nanti bisa langsung dipakai untuk response API.

class Track {
  const Track({
    required this.videoId,
    required this.title,
    required this.artist,
    required this.durationS,
    this.thumbnail,
  });

  /// ID video YouTube — primary key `Track` di backend.
  final String videoId;
  final String title;
  final String artist;
  final int durationS;

  /// URL cover dari YouTube. Null = pakai cover gradient placeholder.
  final String? thumbnail;

  Duration get duration => Duration(seconds: durationS);

  factory Track.fromJson(Map<String, dynamic> j) => Track(
        videoId: j['videoId'] as String,
        title: j['title'] as String,
        artist: j['artist'] as String,
        durationS: j['durationS'] as int,
        thumbnail: j['thumbnail'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'videoId': videoId,
        'title': title,
        'artist': artist,
        'durationS': durationS,
        'thumbnail': thumbnail,
      };

  @override
  bool operator ==(Object other) => other is Track && other.videoId == videoId;

  @override
  int get hashCode => videoId.hashCode;
}

class Playlist {
  const Playlist({required this.id, required this.name, required this.tracks});

  final String id;
  final String name;
  final List<Track> tracks;

  Duration get totalDuration =>
      tracks.fold(Duration.zero, (sum, t) => sum + t.duration);

  Playlist copyWith({String? name, List<Track>? tracks}) =>
      Playlist(id: id, name: name ?? this.name, tracks: tracks ?? this.tracks);

  factory Playlist.fromJson(Map<String, dynamic> j) => Playlist(
        id: j['id'] as String,
        name: j['name'] as String,
        tracks: [
          for (final t in (j['tracks'] as List? ?? const []))
            Track.fromJson(t as Map<String, dynamic>),
        ],
      );
}

class HistoryEntry {
  const HistoryEntry({required this.track, required this.playedAt});

  final Track track;
  final DateTime playedAt;

  factory HistoryEntry.fromJson(Map<String, dynamic> j) => HistoryEntry(
        track: Track.fromJson(j['track'] as Map<String, dynamic>),
        playedAt: DateTime.parse(j['playedAt'] as String),
      );
}

class AppUser {
  const AppUser({required this.id, required this.username});

  final String id;
  final String username;

  factory AppUser.fromJson(Map<String, dynamic> j) =>
      AppUser(id: j['id'] as String, username: j['username'] as String);
}

class LyricLine {
  const LyricLine(this.time, this.text);

  final Duration time;
  final String text;
}

/// Hasil teratas di pencarian bisa berupa artis atau lagu.
class SearchResult {
  const SearchResult({this.topArtist, required this.tracks});

  final String? topArtist;
  final List<Track> tracks;

  bool get isEmpty => topArtist == null && tracks.isEmpty;
}

enum AudioQuality { low, normal, high }
