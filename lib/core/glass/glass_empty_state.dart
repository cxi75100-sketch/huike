import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'glass_surface.dart';

class GlassEmptyState extends StatelessWidget {
  const GlassEmptyState({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = AppTheme.paletteOf(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassSurface(
          radius: 20,
          intensity: GlassIntensity.subtle,
          blurSigma: 12,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: palette.ink,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: palette.inkSecondary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
