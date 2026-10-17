import 'package:flutter/material.dart';

/// Token warna — sama persis dengan variabel di `Pendev/MyMusicMockup.pen`.
abstract final class AppColors {
  static const background = Color(0xFF0E0E12);
  static const surface = Color(0xFF18181F);
  static const surfaceRaised = Color(0xFF22222B);
  static const border = Color(0xFF2E2E3A);

  static const textPrimary = Color(0xFFF5F5F7);
  static const textSecondary = Color(0xFFA0A0AE);
  static const textMuted = Color(0xFF6B6B78);

  static const accent = Color(0xFFE11D2E);
  static const accentSoft = Color(0x29E11D2E);

  static const success = Color(0xFF3DD68C);
  static const error = Color(0xFFFF7A85);
}

abstract final class AppRadius {
  static const sm = 8.0;
  static const card = 12.0;
  static const sheet = 20.0;
  static const pill = 999.0;
}

abstract final class AppSpace {
  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s6 = 24.0;
  static const s8 = 32.0;
}
