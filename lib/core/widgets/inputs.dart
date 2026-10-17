import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';

/// Chip/Default & Chip/Active.
class AppChip extends StatelessWidget {
  const AppChip({super.key, required this.label, this.active = false, this.onTap});

  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.accentSoft : Colors.transparent,
      shape: StadiumBorder(side: BorderSide(color: active ? AppColors.accent : AppColors.border)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: AppText.caption(active ? AppColors.accent : AppColors.textSecondary).copyWith(
              fontSize: 13,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// SearchBar — pill dengan ikon search & tombol clear.
class SearchField extends StatefulWidget {
  const SearchField({
    super.key,
    required this.controller,
    required this.onSubmitted,
    required this.onCleared,
    this.focusNode,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onCleared;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.only(left: 16, right: 4),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Row(children: [
        const Icon(LucideIcons.search, size: 20, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            autofocus: widget.autofocus,
            textInputAction: TextInputAction.search,
            onSubmitted: widget.onSubmitted,
            style: AppText.body(),
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hintText: 'Cari lagu atau artis',
              hintStyle: AppText.body(AppColors.textMuted),
            ),
          ),
        ),
        if (widget.controller.text.isNotEmpty)
          IconButton(
            onPressed: () {
              widget.controller.clear();
              widget.onCleared();
            },
            icon: const Icon(LucideIcons.x, size: 18, color: AppColors.textMuted),
            tooltip: 'Hapus',
          ),
      ]),
    );
  }
}

/// Input form (login, daftar, buat playlist) dengan label & pesan error.
class LabeledField extends StatefulWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.obscure = false,
    this.hasError = false,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.autofocus = false,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool obscure;
  final bool hasError;
  final TextCapitalization textCapitalization;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  @override
  State<LabeledField> createState() => _LabeledFieldState();
}

class _LabeledFieldState extends State<LabeledField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.card), borderSide: BorderSide(color: c));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(widget.label, style: AppText.caption()),
      const SizedBox(height: 8),
      TextField(
        controller: widget.controller,
        obscureText: _hidden,
        autofocus: widget.autofocus,
        textCapitalization: widget.textCapitalization,
        textInputAction: widget.textInputAction,
        onSubmitted: widget.onSubmitted,
        style: AppText.body(),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.surface,
          hintText: widget.hint,
          hintStyle: AppText.body(AppColors.textMuted),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          enabledBorder: border(widget.hasError ? AppColors.error : Colors.transparent),
          focusedBorder: border(widget.hasError ? AppColors.error : AppColors.accent),
          suffixIcon: widget.obscure
              ? IconButton(
                  onPressed: () => setState(() => _hidden = !_hidden),
                  tooltip: _hidden ? 'Tampilkan password' : 'Sembunyikan password',
                  icon: Icon(_hidden ? LucideIcons.eyeOff : LucideIcons.eye, size: 20, color: AppColors.textMuted),
                )
              : null,
        ),
      ),
    ]);
  }
}

class ErrorText extends StatelessWidget {
  const ErrorText(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Icon(LucideIcons.circleAlert, size: 16, color: AppColors.error),
      const SizedBox(width: 6),
      Expanded(child: Text(message, style: AppText.caption(AppColors.error))),
    ]);
  }
}
