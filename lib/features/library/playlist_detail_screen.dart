import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../core/format.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/cover_art.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/inputs.dart';
import '../../core/widgets/track_tile.dart';
import '../../data/models/models.dart';
import '../../data/providers.dart';
import '../player/player_controller.dart';

/// G — Detail Playlist.
///
/// Data:  GET /playlists/:id
///        Ubah nama → PATCH /playlists/:id,  Hapus → DELETE /playlists/:id
class PlaylistDetailScreen extends ConsumerWidget {
  const PlaylistDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlist = ref.watch(playlistProvider(id));
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: playlist.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
          error: (e, _) => Center(child: ErrorText('$e')),
          data: (p) => p == null
              ? Center(
                  child: EmptyState(
                    icon: LucideIcons.listMusic,
                    title: 'Playlist tidak ditemukan',
                    actionLabel: 'Kembali',
                    onAction: () => context.go('/library'),
                  ),
                )
              : _Body(playlist: p),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.playlist});

  final Playlist playlist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracks = playlist.tracks;
    final player = ref.read(playerProvider.notifier);
    final shuffle = ref.watch(playerProvider.select((s) => s.shuffle));

    void playFrom(int i) => player.playTracks(tracks, i, source: playlist.name);

    return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
        child: Row(children: [
          TapIcon(icon: LucideIcons.chevronLeft, size: 26, tooltip: 'Kembali', onTap: () => context.canPop() ? context.pop() : context.go('/library')),
          const Spacer(),
          TapIcon(icon: LucideIcons.ellipsisVertical, tooltip: 'Opsi playlist', onTap: () => _showPlaylistMenu(context, ref, playlist)),
        ]),
      ),
      const SizedBox(height: 8),
      Center(child: PlaylistCover(playlist: playlist, size: 200)),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(playlist.name, style: AppText.display().copyWith(fontSize: 24)),
          const SizedBox(height: 4),
          Text('${tracks.length} lagu • ${formatLongDuration(playlist.totalDuration)}', style: AppText.caption()),
          const SizedBox(height: 16),
          Row(children: [
            CircleIconButton(
              icon: LucideIcons.play,
              size: 52,
              iconSize: 22,
              background: AppColors.accent,
              tooltip: 'Putar',
              onPressed: tracks.isEmpty ? null : () => playFrom(0),
            ),
            const SizedBox(width: 12),
            CircleIconButton(
              icon: LucideIcons.shuffle,
              color: shuffle ? AppColors.accent : AppColors.textPrimary,
              tooltip: 'Acak',
              onPressed: tracks.isEmpty
                  ? null
                  : () {
                      if (!shuffle) player.toggleShuffle();
                      playFrom(Random().nextInt(tracks.length));
                    },
            ),
          ]),
        ]),
      ),
      if (tracks.isEmpty)
        const EmptyState(
          icon: LucideIcons.music,
          title: 'Playlist ini masih kosong',
          message: 'Tambahkan lagu dari menu opsi lagu (ikon titik tiga).',
        )
      else
        for (final (i, t) in tracks.indexed)
          TrackTile(track: t, index: i + 1, onTap: () => playFrom(i)),
    ]);
  }
}

void _showPlaylistMenu(BuildContext context, WidgetRef ref, Playlist p) {
  showAppSheet(context, builder: (sheet) {
    Widget item(IconData icon, String label, VoidCallback onTap, {Color? color}) => ListTile(
          leading: Icon(icon, color: color ?? AppColors.textSecondary),
          title: Text(label, style: AppText.body(color ?? AppColors.textPrimary).copyWith(fontSize: 15)),
          onTap: onTap,
        );
    return Column(mainAxisSize: MainAxisSize.min, children: [
      item(LucideIcons.pencil, 'Ubah nama', () {
        Navigator.pop(sheet);
        _rename(context, ref, p);
      }),
      item(LucideIcons.trash2, 'Hapus playlist', () async {
        Navigator.pop(sheet);
        final ok = await _confirmDelete(context, p);
        if (ok != true || !context.mounted) return;
        try {
          await ref.read(playlistsProvider.notifier).delete(p.id);
        } catch (e) {
          if (context.mounted) showToast(context, '$e', error: true);
          return;
        }
        if (!context.mounted) return;
        context.go('/library');
        showToast(context, 'Playlist ${p.name} dihapus');
      }, color: AppColors.error),
    ]);
  });
}

Future<bool?> _confirmDelete(BuildContext context, Playlist p) => showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: AppColors.surfaceRaised,
        title: Text('Hapus playlist?', style: AppText.title()),
        content: Text('"${p.name}" akan dihapus permanen.', style: AppText.body(AppColors.textSecondary)),
        actions: [
          GhostButton(label: 'Batal', color: AppColors.textSecondary, onPressed: () => Navigator.pop(d, false)),
          GhostButton(label: 'Hapus', color: AppColors.error, onPressed: () => Navigator.pop(d, true)),
        ],
      ),
    );

void _rename(BuildContext context, WidgetRef ref, Playlist p) {
  final controller = TextEditingController(text: p.name);
  showAppSheet(context, builder: (sheet) {
    Future<void> save() async {
      final name = controller.text.trim();
      if (name.isEmpty) return;
      try {
        await ref.read(playlistsProvider.notifier).rename(p.id, name);
        if (sheet.mounted) Navigator.pop(sheet);
      } catch (e) {
        if (context.mounted) showToast(context, '$e', error: true);
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Ubah nama playlist', style: AppText.title().copyWith(fontSize: 18)),
        const SizedBox(height: 16),
        LabeledField(
          label: 'Nama playlist',
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => save(),
        ),
        const SizedBox(height: 20),
        PrimaryButton(label: 'Simpan', expanded: true, onPressed: save),
      ]),
    );
  }).whenComplete(controller.dispose);
}
