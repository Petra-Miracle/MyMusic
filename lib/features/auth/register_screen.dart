import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/buttons.dart';
import '../../core/widgets/inputs.dart';
import '../../data/providers.dart';
import 'login_screen.dart';

/// K — Daftar (khusus pemilik kode undangan).  → POST /auth/register
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

enum _Field { code, username, password, confirm }

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _code = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  (_Field, String)? _error;
  var _loading = false;

  @override
  void dispose() {
    for (final c in [_code, _username, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  (_Field, String)? _validate() {
    if (_code.text.trim().isEmpty) return (_Field.code, 'Kode undangan wajib diisi');
    if (_username.text.trim().length < 3) return (_Field.username, 'Username minimal 3 karakter');
    if (_password.text.length < 6) return (_Field.password, 'Password minimal 6 karakter');
    if (_confirm.text != _password.text) return (_Field.confirm, 'Konfirmasi password tidak sama');
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final invalid = _validate();
    setState(() => _error = invalid);
    if (invalid != null) return;
    setState(() => _loading = true);
    try {
      await ref.read(authProvider.notifier).register(_code.text.trim().toUpperCase(), _username.text, _password.text);
    } catch (e) {
      if (mounted) setState(() => _error = (_Field.code, '$e'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Widget> _field(_Field f, Widget input) => [
        input,
        if (_error?.$1 == f) ...[const SizedBox(height: 8), ErrorText(_error!.$2)],
        const SizedBox(height: 16),
      ];

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Daftar',
      subtitle: 'Khusus pemilik kode undangan',
      showBack: true,
      children: [
        ..._field(
          _Field.code,
          LabeledField(
            label: 'Kode undangan',
            controller: _code,
            hint: 'NADA-XXXXX',
            textCapitalization: TextCapitalization.characters,
            hasError: _error?.$1 == _Field.code,
          ),
        ),
        ..._field(
          _Field.username,
          LabeledField(label: 'Username', controller: _username, hint: 'Masukkan username', hasError: _error?.$1 == _Field.username),
        ),
        ..._field(
          _Field.password,
          LabeledField(
            label: 'Password',
            controller: _password,
            hint: 'Masukkan password',
            obscure: true,
            hasError: _error?.$1 == _Field.password,
          ),
        ),
        ..._field(
          _Field.confirm,
          LabeledField(
            label: 'Konfirmasi password',
            controller: _confirm,
            hint: 'Ulangi password',
            obscure: true,
            hasError: _error?.$1 == _Field.confirm,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(height: 8),
        PrimaryButton(label: 'Daftar', expanded: true, loading: _loading, onPressed: _submit),
      ],
    );
  }
}
