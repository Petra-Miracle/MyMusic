import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/inputs.dart';
import '../../data/providers.dart';

/// J — Masuk.  → POST /auth/login
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  var _loading = false;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).login(_username.text, _password.text);
      // Router redirect ke /home otomatis.
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Masuk',
      subtitle: 'Dengerin musik tanpa langganan',
      showLogo: true,
      children: [
        LabeledField(label: 'Username', controller: _username, hint: 'Masukkan username', hasError: _error != null),
        const SizedBox(height: 16),
        LabeledField(
          label: 'Password',
          controller: _password,
          hint: 'Masukkan password',
          obscure: true,
          hasError: _error != null,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
        ),
        if (_error != null) ...[const SizedBox(height: 12), ErrorText(_error!)],
        const SizedBox(height: 24),
        PrimaryButton(label: 'Masuk', expanded: true, loading: _loading, onPressed: _submit),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => context.push('/register'),
            child: Text('Punya kode undangan? Daftar', style: AppText.bodyStrong(AppColors.accent).copyWith(fontSize: 13)),
          ),
        ),
      ],
    );
  }
}

/// Kerangka bersama layar Masuk & Daftar.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.showLogo = false,
    this.showBack = false,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final bool showLogo;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (showBack)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TapIcon(icon: LucideIcons.chevronLeft, size: 26, onTap: () => context.pop(), tooltip: 'Kembali'),
                  ),
                if (showLogo) ...[const AppLogo(size: 40), const SizedBox(height: 20)],
                Text(title, style: AppText.display()),
                const SizedBox(height: 4),
                Text(subtitle, style: AppText.body(AppColors.textSecondary)),
                const SizedBox(height: 32),
                ...children,
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
