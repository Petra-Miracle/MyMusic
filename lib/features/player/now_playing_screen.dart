import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/cover_art.dart';
import '../../core/widgets/feedback.dart';
import '../../data/providers.dart';
import '../sheets/track_sheets.dart';
import 'player_controller.dart';
import 'queue_sheet.dart';
import 'widgets.dart';

/// C — Now Playing / C2 — Buffering / C3 — Error.
///
/// Data:  Suka → PUT/DELETE /likes/:videoId
///        Tambah ke playlist → POST /playlists/:id/tracks
class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(playerProvider);
    final track = s.current;
    if (track == null) {
      return Scaffold(body: Center(child: GhostButton(label: 'Tutup', onPressed: () => context.pop())));
    }
    final ctrl = ref.read(playerProvider.notifier);
    final liked = ref.watch(likesProvider).value?.contains(track) ?? false;
    final isError = s.status == PlaybackStatus.error;
    final tint = gradientFor(track.videoId).first;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0, 0.6],
            colors: [Color.lerp(tint, AppColors.background, 0.55)!, AppColors.background],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
            child: Column(children: [
              Row(children: [
                TapIcon(icon: LucideIcons.chevronDown, size: 26, tooltip: 'Tutup', onTap: () => context.pop()),
                Expanded(
                  child: Text(
                    'Diputar dari: ${s.source}',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption(),
                  ),
                ),
                TapIcon(icon: LucideIcons.ellipsisVertical, tooltip: 'Opsi lagu', onTap: () => showTrackOptions(context, track)),
              ]),
              Expanded(
                child: LayoutBuilder(builder: (context, c) {
                  final size = min(c.maxWidth, c.maxHeight - 24).clamp(120.0, 380.0);
                  return Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: CoverArt.track(track, key: ValueKey(track.videoId), size: size, radius: 16, shadow: true),
                    ),
                  );
                }),
              ),
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.title().copyWith(fontSize: 22)),
                    const SizedBox(height: 4),
                    Text(track.artist, style: AppText.body(AppColors.textSecondary)),
                  ]),
                ),
                IconButton(
                  tooltip: liked ? 'Hapus dari disukai' : 'Suka',
                  onPressed: () async {
                    if (!await ref.read(likesProvider.notifier).toggle(track) && context.mounted) {
                      showToast(context, 'Gagal menyimpan, periksa koneksi', error: true);
                    }
                  },
                  icon: Icon(
                    liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    size: 26,
                    color: liked ? AppColors.accent : AppColors.textPrimary,
                  ),
                ),
              ]),
              if (isError) ...[
                const SizedBox(height: 16),
                const Icon(LucideIcons.circleAlert, color: AppColors.error, size: 26),
                const SizedBox(height: 8),
                Text('Gagal memutar lagu', style: AppText.bodyStrong()),
                const SizedBox(height: 12),
                PrimaryButton(label: 'Coba lagi', onPressed: ctrl.retry),
              ],
              const SizedBox(height: 20),
              SeekBar(enabled: !isError),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                TapIcon(
                  icon: LucideIcons.shuffle,
                  color: s.shuffle ? AppColors.accent : AppColors.textSecondary,
                  tooltip: 'Acak',
                  onTap: isError ? null : ctrl.toggleShuffle,
                ),
                TapIcon(icon: LucideIcons.skipBack, size: 28, tooltip: 'Sebelumnya', onTap: ctrl.previous),
                PlayPauseButton(disabled: isError),
                TapIcon(icon: LucideIcons.skipForward, size: 28, tooltip: 'Berikutnya', onTap: ctrl.next),
                TapIcon(
                  icon: s.repeat == RepeatSetting.one ? LucideIcons.repeat1 : LucideIcons.repeat,
                  color: s.repeat == RepeatSetting.off ? AppColors.textSecondary : AppColors.accent,
                  tooltip: switch (s.repeat) {
                    RepeatSetting.off => 'Ulangi semua',
                    RepeatSetting.all => 'Ulangi satu lagu',
                    RepeatSetting.one => 'Matikan ulangi',
                  },
                  onTap: isError ? null : ctrl.cycleRepeat,
                ),
              ]),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  TapIcon(icon: LucideIcons.listMusic, color: AppColors.textSecondary, tooltip: 'Antrean', onTap: () => showQueue(context)),
                  TapIcon(icon: LucideIcons.micVocal, color: AppColors.textSecondary, tooltip: 'Lirik', onTap: () => context.push('/player/lyrics')),
                  TapIcon(
                    icon: LucideIcons.listPlus,
                    color: AppColors.textSecondary,
                    tooltip: 'Tambah ke playlist',
                    onTap: () => showAddToPlaylist(context, track),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
