import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../core/format.dart';
import '../../core/widgets/cover_art.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/inputs.dart';
import '../../core/widgets/track_tile.dart';
import '../../data/models/models.dart';
import '../../data/providers.dart';
import '../player/player_controller.dart';
import '../search/search_screen.dart';

/// A — Beranda / A2 — Beranda (user baru).
///
/// Data:  Baru diputar   → GET /history
///        Pilihan cepat  → client-side (lagu serupa dari YouTube)
///        Playlist kamu  → GET /playlists
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    final history = ref.watch(historyProvider);
    final isNewUser = history.hasValue && history.value!.isEmpty;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () async {
            ref.invalidate(historyProvider);
            ref.invalidate(playlistsProvider);
            await ref.read(historyProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.only(top: 12, bottom: 24),
            children: [
              _Header(name: user?.username ?? ''),
              const SizedBox(height: 28),
              if (isNewUser) const _NewUserEmpty() else ...const [_RecentlyPlayed(), SizedBox(height: 32), _QuickPicks()],
              if (!isNewUser) ...const [SizedBox(height: 32), _YourPlaylists()],
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final display = name.isEmpty ? '' : ', ${name[0].toUpperCase()}${name.substring(1)}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        Expanded(child: Text('${greetingFor(DateTime.now())}$display', style: AppText.title())),
        Tooltip(
          message: 'Profil',
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => context.push('/profile'),
            child: CoverArt(seed: 'avatar-$name', size: 40, circle: true),
          ),
        ),
      ]),
    );
  }
}

class _RecentlyPlayed extends ConsumerWidget {
  const _RecentlyPlayed();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentlyPlayedProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionTitle('Baru diputar'),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: recent.when(
          loading: () => const _GridSkeleton(),
          error: (e, _) => ErrorText('Gagal memuat riwayat'),
          data: (tracks) => LayoutBuilder(builder: (context, c) {
            final w = (c.maxWidth - 12) / 2;
            return Wrap(spacing: 12, runSpacing: 16, children: [
              for (final (i, t) in tracks.indexed)
                SizedBox(
                  width: w,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    onTap: () => ref.read(playerProvider.notifier).playTracks(tracks, i, source: 'Baru diputar'),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      CoverArt.track(t, size: w, radius: AppRadius.card),
                      const SizedBox(height: 8),
                      Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption(AppColors.textPrimary).copyWith(fontSize: 13)),
                    ]),
                  ),
                ),
            ]);
          }),
        ),
      ),
    ]);
  }
}

class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton();

  @override
  Widget build(BuildContext context) {
    return Pulse(
      child: LayoutBuilder(builder: (context, c) {
        final w = (c.maxWidth - 12) / 2;
        return Wrap(spacing: 12, runSpacing: 16, children: [
          for (var i = 0; i < 4; i++)
            Container(
              width: w,
              height: w,
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.card)),
            ),
        ]);
      }),
    );
  }
}

class _QuickPicks extends ConsumerWidget {
  const _QuickPicks();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final picks = ref.watch(quickPicksProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionTitle('Pilihan cepat untukmu'),
      ...picks.when(
        loading: () => [for (var i = 0; i < 4; i++) const Pulse(child: TrackTileSkeleton())],
        error: (_, _) => [const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: ErrorText('Gagal memuat rekomendasi'))],
        data: (tracks) => [
          for (final (i, t) in tracks.indexed)
            TrackTile(
              track: t,
              onTap: () => ref.read(playerProvider.notifier).playTracks(tracks, i, source: 'Pilihan cepat'),
            ),
        ],
      ),
    ]);
  }
}

class _YourPlaylists extends ConsumerWidget {
  const _YourPlaylists();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistsProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SectionTitle('Playlist kamu'),
      SizedBox(
        height: 196,
        child: playlists.when(
          loading: () => const SizedBox(),
          error: (_, _) => const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: ErrorText('Gagal memuat playlist')),
          data: (list) => ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _PlaylistCard(playlist: list[i]),
          ),
        ),
      ),
    ]);
  }
}

/// PlaylistCard — cover 150, nama, jumlah lagu.
class _PlaylistCard extends StatelessWidget {
  const _PlaylistCard({required this.playlist});

  final Playlist playlist;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.card),
      onTap: () => context.go('/library/playlist/${playlist.id}'),
      child: SizedBox(
        width: 150,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          PlaylistCover(playlist: playlist, size: 150),
          const SizedBox(height: 8),
          Text(playlist.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.bodyStrong()),
          Text('${playlist.tracks.length} lagu', style: AppText.caption().copyWith(fontWeight: FontWeight.w400)),
        ]),
      ),
    );
  }
}

class _NewUserEmpty extends ConsumerWidget {
  const _NewUserEmpty();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Center(
        child: EmptyState(
          icon: LucideIcons.music,
          title: 'Mulai dengerin lagu pertamamu',
          message: 'Cari lagu favoritmu dan kami akan kasih rekomendasi di sini.',
          actionLabel: 'Cari lagu',
          onAction: () => context.go('/search'),
        ),
      ),
      const SizedBox(height: 16),
      const SectionTitle('Jelajahi genre & mood'),
      const GenreChips(),
    ]);
  }
}
