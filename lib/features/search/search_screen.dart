import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/cover_art.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/inputs.dart';
import '../../core/widgets/track_tile.dart';
import '../../data/models/models.dart';
import '../../data/providers.dart';
import '../player/player_controller.dart';

/// B — Cari (kosong) / B2 — Hasil / B3 — Loading / B4 — Tidak ditemukan.
///
/// Data: pencarian → client-side (YouTube), pencarian terakhir → lokal.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

enum _Filter { songs, videos }

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final _controller = TextEditingController(text: ref.read(searchProvider.notifier).query);
  var _filter = _Filter.songs;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search(String q) => ref.read(searchProvider.notifier).search(q);

  @override
  Widget build(BuildContext context) {
    // Sinkronkan teks bila pencarian dipicu dari luar (mis. chip genre di Beranda).
    ref.listen(searchProvider, (_, _) {
      final q = ref.read(searchProvider.notifier).query;
      if (_controller.text != q) _controller.text = q;
    });
    final state = ref.watch(searchProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SearchField(
              controller: _controller,
              onSubmitted: _search,
              onCleared: ref.read(searchProvider.notifier).clear,
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: switch (state) {
                null => const _Idle(key: ValueKey('idle')),
                AsyncValue(isLoading: true) => _Loading(key: const ValueKey('loading'), filter: _filters),
                AsyncValue(:final error?) => _ErrorView(key: const ValueKey('error'), message: '$error', onRetry: () => _search(_controller.text)),
                AsyncValue(:final value?) when value.isEmpty => const _NotFound(key: ValueKey('empty')),
                AsyncValue(:final value?) => _Results(key: const ValueKey('results'), result: value, filters: _filters),
                _ => const SizedBox(),
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget get _filters => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(children: [
          AppChip(label: 'Lagu', active: _filter == _Filter.songs, onTap: () => setState(() => _filter = _Filter.songs)),
          const SizedBox(width: 8),
          AppChip(label: 'Video', active: _filter == _Filter.videos, onTap: () => setState(() => _filter = _Filter.videos)),
        ]),
      );
}

class _Idle extends ConsumerWidget {
  const _Idle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentSearchesProvider);
    return ListView(padding: const EdgeInsets.only(top: 16, bottom: 24), children: [
      if (recent.isNotEmpty) ...[
        const SectionTitle('Pencarian terakhir'),
        for (final q in recent)
          InkWell(
            onTap: () => ref.read(searchProvider.notifier).search(q),
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 4),
              child: Row(children: [
                const Icon(LucideIcons.history, size: 20, color: AppColors.textMuted),
                const SizedBox(width: 12),
                Expanded(child: Text(q, style: AppText.body().copyWith(fontSize: 15))),
                IconButton(
                  onPressed: () => ref.read(recentSearchesProvider.notifier).remove(q),
                  tooltip: 'Hapus dari riwayat',
                  icon: const Icon(LucideIcons.x, size: 18, color: AppColors.textMuted),
                ),
              ]),
            ),
          ),
        const SizedBox(height: 24),
      ],
      const SectionTitle('Jelajahi genre & mood'),
      const GenreChips(),
    ]);
  }
}

/// Chip genre/mood — dipakai di Cari & Beranda (user baru).
class GenreChips extends ConsumerWidget {
  const GenreChips({super.key});

  static const genres = ['Pop Indonesia', 'Lo-fi', 'Galau', 'Workout', 'K-Pop', 'Jazz'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(spacing: 8, runSpacing: 10, children: [
        for (final g in genres)
          AppChip(
            label: g,
            onTap: () {
              ref.read(searchProvider.notifier).search(g);
              context.go('/search');
            },
          ),
      ]),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading({super.key, required this.filter});

  final Widget filter;

  @override
  Widget build(BuildContext context) {
    return ListView(physics: const NeverScrollableScrollPhysics(), children: [
      filter,
      for (var i = 0; i < 7; i++) const Pulse(child: TrackTileSkeleton()),
    ]);
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: EmptyState(icon: LucideIcons.searchX, title: 'Lagu tidak ditemukan', message: 'Coba kata kunci lain.'),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: EmptyState(
        icon: LucideIcons.wifiOff,
        title: 'Pencarian gagal',
        message: 'Periksa koneksi internetmu lalu coba lagi.',
        actionLabel: 'Coba lagi',
        onAction: onRetry,
      ),
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({super.key, required this.result, required this.filters});

  final SearchResult result;
  final Widget filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracks = result.tracks;
    final player = ref.read(playerProvider.notifier);
    return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
      filters,
      if (result.topArtist != null) ...[
        const SectionTitle('Hasil teratas'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _TopArtistCard(
            artist: result.topArtist!,
            onPlay: () {
              final byArtist = tracks.where((t) => t.artist == result.topArtist).toList();
              player.playTracks(byArtist, 0, source: result.topArtist!);
            },
          ),
        ),
        const SizedBox(height: 28),
      ],
      const SectionTitle('Lagu'),
      for (final (i, t) in tracks.indexed)
        TrackTile(track: t, onTap: () => player.playTracks(tracks, i, source: 'Hasil pencarian')),
    ]);
  }
}

class _TopArtistCard extends StatelessWidget {
  const _TopArtistCard({required this.artist, required this.onPlay});

  final String artist;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Row(children: [
        CoverArt(seed: 'artist-$artist', size: 80, circle: true),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(artist, style: AppText.title()),
            const SizedBox(height: 2),
            Text('Artis', style: AppText.caption()),
          ]),
        ),
        CircleIconButton(
          icon: LucideIcons.play,
          onPressed: onPlay,
          background: AppColors.accent,
          size: 48,
          tooltip: 'Putar $artist',
        ),
      ]),
    );
  }
}
