import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import 'buttons.dart';

/// Toast — kartu kecil dengan ikon centang hijau.
void showToast(BuildContext context, String message, {bool error = false}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
    duration: const Duration(seconds: 2),
    padding: EdgeInsets.zero,
    // Scaffold sudah menaruh snackbar di atas Dock, jadi cukup jarak kecil.
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    content: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Icon(error ? LucideIcons.circleAlert : LucideIcons.circleCheck,
            size: 18, color: error ? AppColors.error : AppColors.success),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: AppText.caption(AppColors.textPrimary).copyWith(fontSize: 13))),
      ]),
    ),
  ));
}

/// Ikon besar dalam lingkaran + judul + teks + tombol opsional.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
          child: Icon(icon, size: 34, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        Text(title, textAlign: TextAlign.center, style: AppText.subtitle()),
        if (message != null) ...[
          const SizedBox(height: 8),
          Text(message!, textAlign: TextAlign.center, style: AppText.body(AppColors.textSecondary)),
        ],
        if (actionLabel != null) ...[
          const SizedBox(height: 20),
          PrimaryButton(label: actionLabel!, onPressed: onAction),
        ],
      ]),
    );
  }
}

/// Skeleton/TrackTile.
class TrackTileSkeleton extends StatelessWidget {
  const TrackTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(4)),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.sm)),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [bar(170, 12), const SizedBox(height: 8), bar(110, 10)]),
      ]),
    );
  }
}

/// Animasi berdenyut sederhana untuk skeleton.
class Pulse extends StatefulWidget {
  const Pulse({super.key, required this.child});

  final Widget child;

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: Tween(begin: 0.45, end: 1.0).animate(_c), child: widget.child);
}

/// Judul section ("Baru diputar", "Playlist kamu", …).
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Text(text, style: AppText.subtitle()),
      );
}
