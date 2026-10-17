import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/track_tile.dart';
import '../../data/providers.dart';
import 'player_controller.dart';

/// E — Antrean. Geser ke kiri untuk menghapus, tahan & seret untuk mengurutkan.
Future<void> showQueue(BuildContext context) {
  return showAppSheet(
    context,
    builder: (context) => ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.8),
      child: const _QueueSheet(),
    ),
  );
}

class _QueueSheet extends ConsumerWidget {
  const _QueueSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(playerProvider);
    final ctrl = ref.read(playerProvider.notifier);
    final autoplay = ref.watch(settingsProvider.select((x) => x.autoplay));

    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Text('Antrean', style: AppText.title()),
      ),
      if (s.current != null) ...[
        _Label('Sedang diputar'),
        TrackTile(track: s.current!, onTap: () {}, trailing: const SizedBox(width: 12)),
      ],
      _Label('Berikutnya'),
      Flexible(
        child: s.upNext.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  autoplay ? 'Antrean kosong. Lagu serupa akan diputar otomatis.' : 'Antrean kosong.',
                  style: AppText.body(AppColors.textMuted),
                ),
              )
            : ReorderableListView.builder(
                shrinkWrap: true,
                buildDefaultDragHandles: false,
                itemCount: s.upNext.length,
                onReorderItem: ctrl.reorderQueue,
                proxyDecorator: (child, _, _) => Material(color: AppColors.border, child: child),
                itemBuilder: (context, i) {
                  final t = s.upNext[i];
                  return Dismissible(
                    key: ValueKey('${t.videoId}-$i'),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => ctrl.removeFromQueue(i),
                    background: Container(
                      color: AppColors.error,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      child: const Icon(LucideIcons.trash2, color: AppColors.textPrimary),
                    ),
                    child: Material(
                      color: AppColors.surfaceRaised,
                      child: TrackTile(
                        track: t,
                        onTap: () => ctrl.skipTo(i),
                        trailing: ReorderableDragStartListener(
                          index: i,
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Icon(LucideIcons.gripVertical, size: 20, color: AppColors.textMuted),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
      const Divider(height: 24, color: AppColors.border),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Expanded(child: Text('Autoplay lagu serupa', style: AppText.body().copyWith(fontSize: 15))),
          Switch(value: autoplay, onChanged: ref.read(settingsProvider.notifier).setAutoplay),
        ]),
      ),
    ]);
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Text(text, style: AppText.caption().copyWith(fontSize: 13)),
      );
}
