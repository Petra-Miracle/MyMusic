import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../core/format.dart';
import 'player_controller.dart';

/// Seek bar + waktu berjalan / total.
class SeekBar extends ConsumerStatefulWidget {
  const SeekBar({super.key, this.enabled = true});

  final bool enabled;

  @override
  ConsumerState<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends ConsumerState<SeekBar> {
  double? _dragging;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(playerProvider);
    final total = s.duration.inMilliseconds.toDouble();
    final value = _dragging ?? s.position.inMilliseconds.toDouble().clamp(0, total);
    return Opacity(
      opacity: widget.enabled ? 1 : 0.4,
      child: Column(children: [
        SizedBox(
          height: 24,
          child: Slider(
            value: total == 0 ? 0 : value.toDouble(),
            max: total == 0 ? 1 : total,
            padding: EdgeInsets.zero,
            onChanged: widget.enabled && total > 0 ? (v) => setState(() => _dragging = v) : null,
            onChangeEnd: (v) {
              ref.read(playerProvider.notifier).seek(Duration(milliseconds: v.round()));
              setState(() => _dragging = null);
            },
          ),
        ),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(formatDuration(Duration(milliseconds: value.round())), style: AppText.caption()),
          Text(formatDuration(s.duration), style: AppText.caption()),
        ]),
      ]),
    );
  }
}

/// Tombol play/pause bulat merah, menampilkan spinner saat buffering.
class PlayPauseButton extends ConsumerWidget {
  const PlayPauseButton({super.key, this.size = 72, this.disabled = false});

  final double size;
  final bool disabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(playerProvider.select((s) => s.status));
    final buffering = status == PlaybackStatus.buffering;
    return Material(
      color: disabled ? AppColors.surfaceRaised : AppColors.accent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: disabled || buffering ? null : ref.read(playerProvider.notifier).togglePlay,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: buffering
                ? SizedBox(
                    width: size * 0.36,
                    height: size * 0.36,
                    child: const CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.textPrimary),
                  )
                : Icon(
                    status == PlaybackStatus.playing ? LucideIcons.pause : LucideIcons.play,
                    size: size * 0.4,
                    color: disabled ? AppColors.textMuted : AppColors.textPrimary,
                  ),
          ),
        ),
      ),
    );
  }
}
