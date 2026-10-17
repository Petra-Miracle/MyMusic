import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/feedback.dart';
import '../../data/models/models.dart';
import '../../data/providers.dart';
import '../sheets/track_sheets.dart';
import 'player_controller.dart';
import 'widgets.dart';

/// D — Lirik / D2 — Lirik tidak tersedia.   Data: LRCLIB (client-side).
class LyricsScreen extends ConsumerWidget {
  const LyricsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(playerProvider.select((s) => s.current));
    if (track == null) {
      return Scaffold(body: Center(child: GhostButton(label: 'Tutup', onPressed: () => context.pop())));
    }
    final lyrics = ref.watch(lyricsProvider(track));
    final ctrl = ref.read(playerProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Row(children: [
              TapIcon(icon: LucideIcons.chevronDown, size: 26, tooltip: 'Tutup', onTap: () => context.pop()),
              Expanded(
                child: Column(children: [
                  Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.subtitle()),
                  Text(track.artist, style: AppText.caption()),
                ]),
              ),
              TapIcon(icon: LucideIcons.ellipsisVertical, tooltip: 'Opsi lagu', onTap: () => showTrackOptions(context, track)),
            ]),
          ),
          Expanded(
            child: lyrics.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
              error: (_, _) => const _Unavailable(),
              data: (lines) => lines == null || lines.isEmpty ? const _Unavailable() : _SyncedLyrics(lines: lines),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Column(children: [
              const SeekBar(),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                TapIcon(icon: LucideIcons.skipBack, size: 26, tooltip: 'Sebelumnya', onTap: ctrl.previous),
                const SizedBox(width: 32),
                const PlayPauseButton(size: 60),
                const SizedBox(width: 32),
                TapIcon(icon: LucideIcons.skipForward, size: 26, tooltip: 'Berikutnya', onTap: ctrl.next),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable();

  @override
  Widget build(BuildContext context) =>
      const Center(child: EmptyState(icon: LucideIcons.micOff, title: 'Lirik tidak tersedia'));
}

class _SyncedLyrics extends ConsumerStatefulWidget {
  const _SyncedLyrics({required this.lines});

  final List<LyricLine> lines;

  @override
  ConsumerState<_SyncedLyrics> createState() => _SyncedLyricsState();
}

class _SyncedLyricsState extends ConsumerState<_SyncedLyrics> {
  late final _keys = List.generate(widget.lines.length, (_) => GlobalKey());
  var _active = -1;

  int _indexAt(Duration pos) => widget.lines.lastIndexWhere((l) => l.time <= pos);

  void _scrollTo(int i) {
    final ctx = i >= 0 ? _keys[i].currentContext : null;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, alignment: 0.4, duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pos = ref.watch(playerProvider.select((s) => s.position));
    final active = _indexAt(pos);
    if (active != _active) {
      _active = active;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTo(active));
    }
    final ctrl = ref.read(playerProvider.notifier);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 120),
      children: [
        for (final (i, line) in widget.lines.indexed)
          InkWell(
            key: _keys[i],
            borderRadius: BorderRadius.circular(8),
            onTap: () => ctrl.seek(line.time),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                textAlign: TextAlign.center,
                style: i == active
                    ? AppText.title().copyWith(fontSize: 22)
                    : AppText.body(AppColors.textMuted).copyWith(fontSize: 16),
                child: Text(line.text, textAlign: TextAlign.center),
              ),
            ),
          ),
      ],
    );
  }
}
