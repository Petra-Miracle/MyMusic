import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/cover_art.dart';
import '../../core/widgets/dock.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/inputs.dart';
import '../../data/models/models.dart';
import '../../data/providers.dart';

/// L — Profil & Pengaturan.
///
/// Data:  Buat kode undangan → POST /invites
///        Keluar             → hapus token lokal
///        Kualitas, autoplay, cache → lokal di HP
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String? _invite;
  var _creatingInvite = false;

  Future<void> _createInvite() async {
    setState(() => _creatingInvite = true);
    try {
      final code = await ref.read(authRepositoryProvider).createInviteCode();
      if (mounted) setState(() => _invite = code);
    } finally {
      if (mounted) setState(() => _creatingInvite = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    final settings = ref.watch(settingsProvider);
    final settingsCtrl = ref.read(settingsProvider.notifier);

    return Scaffold(
      bottomNavigationBar: const Dock(),
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          SizedBox(
            height: 52,
            child: Stack(alignment: Alignment.center, children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: TapIcon(icon: LucideIcons.chevronLeft, size: 26, tooltip: 'Kembali', onTap: () => context.pop()),
                ),
              ),
              Text('Profil', style: AppText.subtitle()),
            ]),
          ),
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
              Row(children: [
                CoverArt(seed: 'avatar-${user?.username}', size: 64, circle: true),
                const SizedBox(width: 16),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_capitalize(user?.username ?? ''), style: AppText.title()),
                  Text('@${user?.username ?? ''}', style: AppText.caption()),
                ]),
              ]),
              const _Section('Pemutaran'),
              Row(children: [
                Expanded(child: Text('Kualitas audio', style: AppText.body().copyWith(fontSize: 15))),
                for (final (q, label) in const [
                  (AudioQuality.low, 'Rendah'),
                  (AudioQuality.normal, 'Normal'),
                  (AudioQuality.high, 'Tinggi'),
                ]) ...[
                  const SizedBox(width: 6),
                  AppChip(label: label, active: settings.quality == q, onTap: () => settingsCtrl.setQuality(q)),
                ],
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: Text('Autoplay lagu serupa', style: AppText.body().copyWith(fontSize: 15))),
                Switch(value: settings.autoplay, onChanged: settingsCtrl.setAutoplay),
              ]),
              const _Section('Undang teman'),
              SecondaryButton(
                label: _creatingInvite ? 'Membuat kode…' : 'Buat kode undangan',
                expanded: true,
                onPressed: _creatingInvite ? null : _createInvite,
              ),
              if (_invite != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.only(left: 16, right: 4),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.card)),
                  child: Row(children: [
                    Expanded(
                      child: Text(_invite!, style: AppText.subtitle().copyWith(letterSpacing: 1.5, fontSize: 15)),
                    ),
                    IconButton(
                      tooltip: 'Salin kode',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _invite!));
                        showToast(context, 'Kode undangan disalin');
                      },
                      icon: const Icon(LucideIcons.copy, size: 20, color: AppColors.accent),
                    ),
                  ]),
                ),
              ],
              const _Section('Penyimpanan'),
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Hapus cache', style: AppText.body().copyWith(fontSize: 15)),
                    Text('120 MB', style: AppText.caption()),
                  ]),
                ),
                SecondaryButton(label: 'Hapus', onPressed: () => showToast(context, 'Cache dihapus')),
              ]),
              const _Section('Tentang'),
              Row(children: [
                Expanded(child: Text('Versi aplikasi', style: AppText.body().copyWith(fontSize: 15))),
                Text('1.0.0', style: AppText.body(AppColors.textSecondary)),
              ]),
              const SizedBox(height: 32),
              Center(
                child: GhostButton(
                  label: 'Keluar',
                  color: AppColors.error,
                  onPressed: () => ref.read(authProvider.notifier).logout(),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  static String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 28, bottom: 12),
        child: Text(title, style: AppText.caption(AppColors.textMuted).copyWith(fontSize: 13)),
      );
}
