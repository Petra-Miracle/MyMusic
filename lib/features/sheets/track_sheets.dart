import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/cover_art.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/inputs.dart';
import '../../data/models/models.dart';
import '../../data/providers.dart';
import '../player/player_controller.dart';

/// S1 — Opsi lagu.
Future<void> showTrackOptions(BuildContext context, Track track) {
  return showAppSheet(context, builder: (_) => _TrackOptionsSheet(track: track));
}

/// S2 — Tambah ke playlist.
Future<void> showAddToPlaylist(BuildContext context, Track track) {
  return showAppSheet(context, builder: (_) => _AddToPlaylistSheet(track: track));
}

/// S3 — Buat playlist. Mengembalikan playlist baru (atau null bila batal).
Future<Playlist?> showCreatePlaylist(BuildContext context, {Track? withTrack}) {
  return showAppSheet<Playlist>(context, builder: (_) => _CreatePlaylistSheet(withTrack: withTrack));
}

class _TrackOptionsSheet extends ConsumerWidget {
  const _TrackOptionsSheet({required this.track});

  final Track track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liked = ref.watch(likesProvider).value?.contains(track) ?? false;
    final player = ref.read(playerProvider.notifier);
    final rootContext = Navigator.of(context, rootNavigator: true).context;

    void close() => Navigator.of(context).pop();

    return Column(mainAxisSize: MainAxisSize.min, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Row(children: [
          CoverArt.track(track, size: 52),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.subtitle()),
              Text(track.artist, style: AppText.caption()),
            ]),
          ),
        ]),
      ),
      const Divider(height: 1, color: AppColors.border),
      const SizedBox(height: 4),
      _Option(LucideIcons.listStart, 'Putar berikutnya', () {
        player.playNext(track);
        close();
        showToast(rootContext, 'Diputar setelah lagu ini');
      }),
      _Option(LucideIcons.listPlus, 'Tambah ke antrean', () {
        player.addToQueue(track);
        close();
        showToast(rootContext, 'Ditambahkan ke antrean');
      }),
      _Option(LucideIcons.folderPlus, 'Tambah ke playlist', () {
        close();
        showAddToPlaylist(rootContext, track);
      }),
      _Option(
        LucideIcons.heart,
        liked ? 'Hapus dari disukai' : 'Suka',
        () {
          ref.read(likesProvider.notifier).toggle(track);
          close();
          showToast(rootContext, liked ? 'Dihapus dari lagu yang disukai' : 'Ditambahkan ke lagu yang disukai');
        },
        color: liked ? AppColors.accent : null,
      ),
      _Option(LucideIcons.micVocal, 'Lihat lirik', () {
        close();
        if (ref.read(playerProvider).current != track) {
          player.playTracks([track], 0, source: 'Opsi lagu');
        }
        rootContext.push('/player/lyrics');
      }),
      _Option(LucideIcons.share2, 'Bagikan', () {
        Clipboard.setData(ClipboardData(text: 'https://music.youtube.com/watch?v=${track.videoId}'));
        close();
        showToast(rootContext, 'Link lagu disalin');
      }),
    ]);
  }
}

class _Option extends StatelessWidget {
  const _Option(this.icon, this.label, this.onTap, {this.color});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(children: [
          Icon(icon, size: 22, color: color ?? AppColors.textSecondary),
          const SizedBox(width: 16),
          Text(label, style: AppText.body(c).copyWith(fontSize: 15)),
        ]),
      ),
    );
  }
}

class _AddToPlaylistSheet extends ConsumerWidget {
  const _AddToPlaylistSheet({required this.track});

  final Track track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistsProvider);
    final rootContext = Navigator.of(context, rootNavigator: true).context;

    Future<void> toggle(Playlist p) async {
      final notifier = ref.read(playlistsProvider.notifier);
      if (p.tracks.contains(track)) {
        await notifier.remove(p.id, track.videoId);
        if (rootContext.mounted) showToast(rootContext, 'Dihapus dari playlist ${p.name}');
      } else {
        await notifier.add(p.id, track);
        if (rootContext.mounted) showToast(rootContext, 'Ditambahkan ke playlist ${p.name}');
      }
    }

    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Text('Tambah ke playlist', style: AppText.title().copyWith(fontSize: 18)),
      ),
      InkWell(
        onTap: () async {
          final p = await showCreatePlaylist(context, withTrack: track);
          if (p != null && context.mounted) Navigator.of(context).pop();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(LucideIcons.plus, color: AppColors.accent),
            ),
            const SizedBox(width: 12),
            Text('Playlist baru', style: AppText.bodyStrong(AppColors.accent).copyWith(fontSize: 15)),
          ]),
        ),
      ),
      Flexible(
        child: playlists.when(
          loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
          error: (e, _) => Padding(padding: const EdgeInsets.all(16), child: ErrorText('$e')),
          data: (list) => ListView(
            shrinkWrap: true,
            children: [
              for (final p in list)
                InkWell(
                  onTap: () => toggle(p),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(children: [
                      PlaylistCover(playlist: p, size: 52, radius: AppRadius.sm),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(p.name, style: AppText.body().copyWith(fontSize: 15, fontWeight: FontWeight.w500)),
                          Text('Playlist • ${p.tracks.length} lagu', style: AppText.caption()),
                        ]),
                      ),
                      _CheckBox(checked: p.tracks.contains(track)),
                    ]),
                  ),
                ),
            ],
          ),
        ),
      ),
    ]);
  }
}

class _CheckBox extends StatelessWidget {
  const _CheckBox({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: checked ? AppColors.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: checked ? AppColors.accent : AppColors.border, width: 1.5),
      ),
      child: checked ? const Icon(LucideIcons.check, size: 14, color: AppColors.textPrimary) : null,
    );
  }
}

class _CreatePlaylistSheet extends ConsumerStatefulWidget {
  const _CreatePlaylistSheet({this.withTrack});

  final Track? withTrack;

  @override
  ConsumerState<_CreatePlaylistSheet> createState() => _CreatePlaylistSheetState();
}

class _CreatePlaylistSheetState extends ConsumerState<_CreatePlaylistSheet> {
  final _name = TextEditingController();
  var _saving = false;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    final rootContext = Navigator.of(context, rootNavigator: true).context;
    final notifier = ref.read(playlistsProvider.notifier);
    final p = await notifier.create(name);
    if (widget.withTrack != null) await notifier.add(p.id, widget.withTrack!);
    if (!mounted) return;
    Navigator.of(context).pop(p);
    if (rootContext.mounted) showToast(rootContext, widget.withTrack != null ? 'Ditambahkan ke playlist $name' : 'Playlist $name dibuat');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Buat playlist', style: AppText.title().copyWith(fontSize: 18)),
        const SizedBox(height: 16),
        LabeledField(
          label: 'Nama playlist',
          controller: _name,
          hint: 'Playlist baruku',
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _create(),
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          label: 'Buat',
          expanded: true,
          loading: _saving,
          onPressed: _name.text.trim().isEmpty ? null : _create,
        ),
      ]),
    );
  }
}
