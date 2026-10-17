import 'package:flutter/material.dart';

import '../../core/widgets/app_logo.dart';

/// I — Splash. Ditampilkan selama token dicek (→ GET /auth/me);
/// router otomatis pindah ke /login atau /home setelah selesai.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: AppLogo(size: 56)));
  }
}
