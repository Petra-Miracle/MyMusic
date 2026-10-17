import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../core/format.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/cover_art.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/inputs.dart';
import '../../core/widgets/track_tile.dart';
import '../../data/models/models.dart';
import '../../data/providers.dart';
import '../player/player_controller.dart';
import '../sheets/track_sheets.dart';

enum LibraryTab { playlists, liked, history }

/// F — Koleksi / F2 — Kosong / F3 — Disukai / H — Riwayat.
///
/// Data:  Playlist → GET /playlists
///        Disukai  → GET /likes   (hapus: DELETE /likes/:videoId)
///        Riwayat  → GET /history
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  var _tab = LibraryTab.playlists;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(children: [
              Expanded(child: Text('Koleksi', style: AppText.display().copyWith(fontSize: 24))),
              CircleIconButton(icon: LucideIcons.plus, tooltip: 'Buat playlist', onPressed: () => showCreatePlaylist(context)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(children: [
              for (final (tab, label) in const [
                (LibraryTab.playlists, 'Playlist'),
                (LibraryTab.liked, 'Disukai'),
                (LibraryTab.history, 'Riwayat'),
              ]) ...[
                AppChip(label: label, active: _tab == tab, onTap: () => setState(() => _tab = tab)),
                const SizedBox(width: 8),
              ],
            ]),
          ),
          Expanded(
            child: switch (_tab) {
              LibraryTab.playlists => _PlaylistsTab(onOpenLiked: () => setState(() => _tab = LibraryTab.liked)),
              LibraryTab.liked => const _LikedTab(),
              LibraryTab.history => const _HistoryTab(),
            },
          ),
        ]),
      ),
    );
  }
}

class _PlaylistsTab extends ConsumerWidget {
  const _PlaylistsTab({required this.onOpenLiked});

  final VoidCallback onOpenLiked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistsProvider);
    final likedCount = ref.watch(likesProvider).value?.length ?? 0;

    return playlists.when(
      loading: () => ListView(children: [for (var i = 0; i < 6; i++) const Pulse(child: TrackTileSkeleton())]),
      error: (e, _) => Center(
        child: EmptyState(
          icon: LucideIcons.wifiOff,
          title: 'Gagal memuat koleksi',
          actionLabel: 'Coba lagi',
          onAction: () => ref.invalidate(playlistsProvider),
        ),
      ),
      data: (list) => ListView(padding: const EdgeInsets.only(bottom: 24), children: [
        _CollectionRow(
          leading: const LikedCover(size: 56),
          title: 'Lagu yang disukai',
          subtitle: '$likedCount lagu',
          onTap: onOpenLiked,
        ),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 48),
            child: EmptyState(
              icon: LucideIcons.listMusic,
              title: 'Belum ada playlist',
              actionLabel: 'Buat playlist',
              onAction: () => showCreatePlaylist(context),
            ),
          )
        else
          for (final p in list)
            _CollectionRow(
              leading: PlaylistCover(playlist: p, size: 56, radius: AppRadius.sm),
              title: p.name,
              subtitle: 'Playlist • ${p.tracks.length} lagu',
              onTap: () => context.go('/library/playlist/${p.id}'),
            ),
      ]),
    );
  }
}

class _CollectionRow extends StatelessWidget {
  const _CollectionRow({required this.leading, required this.title, required this.subtitle, required this.onTap});

  final Widget leading;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [
          leading,
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.subtitle().copyWith(fontSize: 15)),
              const SizedBox(height: 2),
              Text(subtitle, style: AppText.caption().copyWith(fontWeight: FontWeight.w400)),
            ]),
          ),
          const Icon(LucideIcons.chevronRight, size: 20, color: AppColors.textMuted),
        ]),
      ),
    );
  }
}

class _LikedTab extends ConsumerWidget {
  const _LikedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likes = ref.watch(likesProvider);
    return likes.when(
      loading: () => ListView(children: [for (var i = 0; i < 6; i++) const Pulse(child: TrackTileSkeleton())]),
      error: (e, _) => Center(child: ErrorText('$e')),
      data: (tracks) => tracks.isEmpty
          ? const Center(
              child: EmptyState(
                icon: LucideIcons.heart,
                title: 'Belum ada lagu yang disukai',
                message: 'Tekan ikon hati di pemutar untuk menyimpan lagu ke sini.',
              ),
            )
          : ListView(padding: const EdgeInsets.only(bottom: 24), children: [
              for (final (i, t) in tracks.indexed)
                TrackTile(
                  track: t,
                  onTap: () => ref.read(playerProvider.notifier).playTracks(tracks, i, source: 'Lagu yang disukai'),
                  trailing: IconButton(
                    tooltip: 'Hapus dari disukai',
                    onPressed: () async {
                      final ok = await ref.read(likesProvider.notifier).toggle(t);
                      if (context.mounted) {
                        showToast(context, ok ? 'Dihapus dari lagu yang disukai' : 'Gagal, periksa koneksi', error: !ok);
                      }
                    },
                    icon: const Icon(Icons.favorite_rounded, size: 20, color: AppColors.accent),
                  ),
                ),
            ]),
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    return history.when(
      loading: () => ListView(children: [for (var i = 0; i < 6; i++) const Pulse(child: TrackTileSkeleton())]),
      error: (e, _) => Center(child: ErrorText('$e')),
      data: (entries) {
        if (entries.isEmpty) {
          return const Center(child: EmptyState(icon: LucideIcons.history, title: 'Belum ada riwayat'));
        }
        // Per hari, lagu yang sama cukup tampil sekali (pemutaran terakhir).
        final groups = <String, List<HistoryEntry>>{};
        for (final e in entries) {
          final day = groups.putIfAbsent(formatDayLabel(e.playedAt), () => []);
          if (!day.any((x) => x.track == e.track)) day.add(e);
        }
        return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
          for (final MapEntry(key: day, value: items) in groups.entries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(day, style: AppText.caption().copyWith(fontSize: 13)),
            ),
            for (final e in items)
              TrackTile(
                track: e.track,
                onTap: () => ref.read(playerProvider.notifier).playTracks([e.track], 0, source: 'Riwayat'),
              ),
          ],
        ]);
      },
    );
  }
}
