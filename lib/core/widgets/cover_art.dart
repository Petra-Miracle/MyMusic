import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../data/models/models.dart';

const _gradients = <List<Color>>[
  [Color(0xFF8B5CF6), Color(0xFFEC4899)],
  [Color(0xFFF59E0B), Color(0xFFEF4444)],
  [Color(0xFF06B6D4), Color(0xFF3B82F6)],
  [Color(0xFF10B981), Color(0xFF0EA5E9)],
  [Color(0xFFF97316), Color(0xFFDB2777)],
  [Color(0xFF6366F1), Color(0xFFA855F7)],
  [Color(0xFFFBBF24), Color(0xFFF472B6)],
  [Color(0xFF14B8A6), Color(0xFF22C55E)],
  [Color(0xFFE11D2E), Color(0xFFF97316)],
  [Color(0xFF0EA5E9), Color(0xFF8B5CF6)],
  [Color(0xFF84CC16), Color(0xFF14B8A6)],
  [Color(0xFFEC4899), Color(0xFFF59E0B)],
];

/// Gradient placeholder yang stabil per lagu (lagu yang sama = warna yang sama di semua layar).
List<Color> gradientFor(String seed) {
  if (seed == 'hati-hati') return _gradients[0];
  // FNV-1a: sebaran lebih merata daripada hash sederhana.
  var hash = 0x811c9dc5;
  for (final c in seed.codeUnits) {
    hash = ((hash ^ c) * 0x01000193) & 0xffffffff;
  }
  return _gradients[hash % _gradients.length];
}

/// Cover lagu: gambar dari YouTube bila ada, kalau tidak gradient placeholder.
class CoverArt extends StatelessWidget {
  const CoverArt({
    super.key,
    required this.seed,
    this.imageUrl,
    required this.size,
    this.radius = AppRadius.sm,
    this.circle = false,
    this.shadow = false,
  });

  CoverArt.track(Track t, {Key? key, required double size, double radius = AppRadius.sm, bool shadow = false})
      : this(key: key, seed: t.videoId, imageUrl: t.thumbnail, size: size, radius: radius, shadow: shadow);

  final String seed;
  final String? imageUrl;
  final double size;
  final double radius;
  final bool circle;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final colors = gradientFor(seed);
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
        boxShadow: shadow
            ? [BoxShadow(color: colors.last.withValues(alpha: 0.35), blurRadius: 40, offset: const Offset(0, 16))]
            : null,
      ),
      child: imageUrl == null ? null : _CoverImage(url: imageUrl!, large: size > 160),
    );
  }
}

/// Thumbnail YouTube kecil (320×180) cukup untuk tile; cover besar memakai versi 1280×720
/// bila ada, dan kembali ke versi kecil bila video lama tidak punya.
class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.url, required this.large});

  final String url;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final small = Image.network(url, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox());
    if (!large || !url.contains('i.ytimg.com') || !url.endsWith('/mqdefault.jpg')) return small;
    return Image.network(
      url.replaceFirst('/mqdefault.jpg', '/hq720.jpg'),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => small,
    );
  }
}

/// Cover playlist: kolase 4 cover lagu pertama (atau 1 bila lagunya < 4).
class PlaylistCover extends StatelessWidget {
  const PlaylistCover({super.key, required this.playlist, required this.size, this.radius = AppRadius.card});

  final Playlist playlist;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final tracks = playlist.tracks;
    if (tracks.length < 4) {
      return CoverArt(
        seed: tracks.isEmpty ? playlist.id : tracks.first.videoId,
        imageUrl: tracks.firstOrNull?.thumbnail,
        size: size,
        radius: radius,
      );
    }
    final half = size / 2;
    Widget cell(Track t) => CoverArt.track(t, size: half, radius: 0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: Column(children: [
          Row(children: [cell(tracks[0]), cell(tracks[1])]),
          Row(children: [cell(tracks[2]), cell(tracks[3])]),
        ]),
      ),
    );
  }
}

/// Cover khusus "Lagu yang disukai".
class LikedCover extends StatelessWidget {
  const LikedCover({super.key, required this.size, this.radius = AppRadius.sm});

  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accent, Color(0xFF7A0F19)],
        ),
      ),
      child: Icon(Icons.favorite_border_rounded, color: AppColors.textPrimary, size: size * 0.42),
    );
  }
}
