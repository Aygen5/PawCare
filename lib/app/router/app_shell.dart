import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/paw_bottom_nav.dart';

/// PawCare ana uygulama iskeleti; 480px mobil genişlik sınırı ve alt navigasyon barını barındırır.
class AppShell extends StatelessWidget {
  final Widget? child;
  final bool initialShowingWelcome;

  const AppShell({
    super.key,
    this.child,
    this.initialShowingWelcome = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121B15)
          : const Color(0xFFEFECE5),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBackground : AppColors.background,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 32,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Sayfa ana gövdesi (GoRouter tarafından iletilen rota içeriği)
                Expanded(
                  child: child ?? const SizedBox.shrink(),
                ),
                // Alt gezinme çubuğu
                const PawBottomNav(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
