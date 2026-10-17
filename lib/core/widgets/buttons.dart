import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';

/// Button/Primary — fill merah, pill.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textPrimary),
          )
        : Text(label, style: AppText.bodyStrong());
    return Opacity(
      opacity: onPressed == null && !loading ? 0.4 : 1,
      child: _PillButton(
        onPressed: loading ? null : onPressed,
        background: AppColors.accent,
        expanded: expanded,
        child: child,
      ),
    );
  }
}

/// Button/Secondary — outline.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, required this.onPressed, this.expanded = false});

  final String label;
  final VoidCallback? onPressed;
  final bool expanded;

  @override
  Widget build(BuildContext context) => _PillButton(
        onPressed: onPressed,
        border: AppColors.border,
        expanded: expanded,
        child: Text(label, style: AppText.bodyStrong()),
      );
}

/// Button/Ghost — teks saja.
class GhostButton extends StatelessWidget {
  const GhostButton({super.key, required this.label, required this.onPressed, this.color = AppColors.accent});

  final String label;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) => _PillButton(
        onPressed: onPressed,
        child: Text(label, style: AppText.bodyStrong(color)),
      );
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.onPressed,
    required this.child,
    this.background,
    this.border,
    this.expanded = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color? background;
  final Color? border;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background ?? Colors.transparent,
      shape: StadiumBorder(side: border == null ? BorderSide.none : BorderSide(color: border!)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          height: 46,
          width: expanded ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: expanded ? Alignment.center : null,
          child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [child]),
        ),
      ),
    );
  }
}

/// Button/Icon — bulat, latar surface-raised.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 44,
    this.iconSize = 20,
    this.background = AppColors.surfaceRaised,
    this.color = AppColors.textPrimary,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final Color background;
  final Color color;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: background,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(width: size, height: size, child: Icon(icon, size: iconSize, color: color)),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// Ikon polos yang bisa ditekan (tanpa latar), area sentuh minimal 40.
class TapIcon extends StatelessWidget {
  const TapIcon({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 22,
    this.color = AppColors.textPrimary,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color color;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: Icon(icon, size: size, color: onTap == null ? color.withValues(alpha: 0.4) : color),
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
    );
  }
}
