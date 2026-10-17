import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// Logo "Nada": ikon merah (dari Gemini) + wordmark.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 44, this.showText = true});

  final double size;
  final bool showText;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.26),
        child: Image.asset('assets/images/logo.png', width: size, height: size),
      ),
      if (showText) ...[
        SizedBox(width: size * 0.3),
        Text('Nada', style: AppText.title().copyWith(fontSize: size * 0.5, letterSpacing: -0.3)),
      ],
    ]);
  }
}
