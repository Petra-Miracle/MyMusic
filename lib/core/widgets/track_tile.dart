import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../features/player/player_controller.dart';
import '../../features/sheets/track_sheets.dart';
import '../format.dart';
import 'cover_art.dart';

/// TrackTile — cover 48, judul, artis · durasi, tombol more.
/// Otomatis tampil "sedang diputar" (judul merah + ikon equalizer) bila lagunya aktif.
class TrackTile extends ConsumerWidget {
  const TrackTile({
    super.key,
    required this.track,
    required this.onTap,
    this.index,
    this.trailing,
    this.showDuration = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  final Track track;
  final VoidCallback onTap;

  /// Nomor urut (dipakai di Detail Playlist).
  final int? index;

  /// Ganti tombol "more" (mis. ikon hati di tab Disukai, drag handle di Antrean).
  final Widget? trailing;
  final bool showDuration;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCurrent = ref.watch(playerProvider.select((s) => s.current == track));
    return InkWell(
      onTap: onTap,
      onLongPress: () => showTrackOptions(context, track),
      child: Padding(
        padding: padding,
        child: Row(children: [
          if (index != null)
            SizedBox(
              width: 28,
              child: Text('$index', style: AppText.caption(isCurrent ? AppColors.accent : AppColors.textMuted)),
            ),
          CoverArt.track(track, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                track.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(isCurrent ? AppColors.accent : AppColors.textPrimary)
                    .copyWith(fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400),
              ),
              const SizedBox(height: 2),
              Text(
                showDuration ? '${track.artist}  ·  ${formatDuration(track.duration)}' : track.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.caption(),
              ),
            ]),
          ),
          if (isCurrent) ...[
            const SizedBox(width: 8),
            const Icon(LucideIcons.audioLines, size: 18, color: AppColors.accent),
          ],
          trailing ??
              IconButton(
                onPressed: () => showTrackOptions(context, track),
                tooltip: 'Opsi lagu',
                icon: const Icon(LucideIcons.ellipsisVertical, size: 20, color: AppColors.textMuted),
              ),
        ]),
      ),
    );
  }
}
