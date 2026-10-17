import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../features/player/player_controller.dart';
import 'cover_art.dart';

/// Dock bawah: MiniPlayer (bila ada lagu) + BottomNav (opsional).
class Dock extends ConsumerWidget {
  const Dock({super.key, this.currentTab, this.onTabSelected});

  /// Null = tanpa BottomNav (mis. halaman Profil).
  final int? currentTab;
  final ValueChanged<int>? onTabSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasTrack = ref.watch(playerProvider.select((s) => s.current != null));
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (hasTrack) const MiniPlayer(),
          if (hasTrack && currentTab != null) const SizedBox(height: 12),
          if (currentTab != null) BottomNav(current: currentTab!, onSelected: onTabSelected!),
        ]),
      ),
    );
  }
}

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(playerProvider);
    final track = s.current!;
    final ctrl = ref.read(playerProvider.notifier);
    return Material(
      color: AppColors.surfaceRaised,
      borderRadius: BorderRadius.circular(AppRadius.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/player'),
        child: SizedBox(
          height: 64,
          child: Column(children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 10, right: 4),
                child: Row(children: [
                  CoverArt.track(track, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bodyStrong()),
                      Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption().copyWith(fontWeight: FontWeight.w400)),
                    ]),
                  ),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: s.status == PlaybackStatus.buffering
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textPrimary),
                          )
                        : IconButton(
                            onPressed: ctrl.togglePlay,
                            tooltip: s.isPlaying ? 'Jeda' : 'Putar',
                            icon: Icon(
                              s.status == PlaybackStatus.error
                                  ? LucideIcons.rotateCcw
                                  : s.isPlaying
                                      ? LucideIcons.pause
                                      : LucideIcons.play,
                              size: 22,
                              color: AppColors.textPrimary,
                            ),
                          ),
                  ),
                  IconButton(
                    onPressed: ctrl.next,
                    tooltip: 'Berikutnya',
                    icon: const Icon(LucideIcons.skipForward, size: 22, color: AppColors.textPrimary),
                  ),
                ]),
              ),
            ),
            LinearProgressIndicator(
              value: s.progress,
              minHeight: 2,
              backgroundColor: AppColors.border,
              color: AppColors.accent,
            ),
          ]),
        ),
      ),
    );
  }
}

class BottomNav extends StatelessWidget {
  const BottomNav({super.key, required this.current, required this.onSelected});

  final int current;
  final ValueChanged<int> onSelected;

  static const _items = [
    (LucideIcons.house, 'Beranda'),
    (LucideIcons.search, 'Cari'),
    (LucideIcons.libraryBig, 'Koleksi'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(color: AppColors.surfaceRaised, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Row(children: [
        for (final (i, (icon, label)) in _items.indexed)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Material(
                color: i == current ? AppColors.accentSoft : Colors.transparent,
                shape: const StadiumBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => onSelected(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(children: [
                      Icon(icon, size: 22, color: i == current ? AppColors.accent : AppColors.textMuted),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: AppText.label(i == current ? AppColors.accent : AppColors.textMuted)
                            .copyWith(fontWeight: i == current ? FontWeight.w600 : FontWeight.w500),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}
