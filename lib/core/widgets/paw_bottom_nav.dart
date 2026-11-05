import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/route_names.dart';
import '../../domain/entities/user_role.dart';
import '../../features/auth/cubit/role_cubit.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// PawCare rol bazlı ve GoRouter ile senkronize alt gezinme çubuğu.
class PawBottomNav extends StatelessWidget {
  const PawBottomNav({super.key});

  int _calculateCurrentIndex(BuildContext context, bool isOwner) {
    try {
      final location = GoRouterState.of(context).uri.path;
      if (isOwner) {
        if (location.startsWith(RoutePaths.explore)) return 1;
        if (location.startsWith(RoutePaths.pets)) return 2;
        if (location.startsWith(RoutePaths.bookings)) return 3;
        if (location.startsWith(RoutePaths.profile)) return 4;
        if (location.startsWith(RoutePaths.home)) return 0;
      } else {
        if (location.startsWith(RoutePaths.sitterListing)) return 1;
        if (location.startsWith(RoutePaths.sitterCalendar)) return 2;
        if (location.startsWith(RoutePaths.sitterReviews)) return 3;
        if (location.startsWith(RoutePaths.profile)) return 4;
        if (location.startsWith(RoutePaths.sitterDashboard)) return 0;
      }
    } catch (_) {
      // GoRouter henüz bağlı değilse varsayılan 0
    }
    return 0;
  }

  void _onItemTapped(BuildContext context, bool isOwner, int index) {
    if (isOwner) {
      switch (index) {
        case 0:
          context.go(RoutePaths.home);
          break;
        case 1:
          context.go(RoutePaths.explore);
          break;
        case 2:
          context.go(RoutePaths.pets);
          break;
        case 3:
          context.go(RoutePaths.bookings);
          break;
        case 4:
          context.go(RoutePaths.profile);
          break;
      }
    } else {
      switch (index) {
        case 0:
          context.go(RoutePaths.sitterDashboard);
          break;
        case 1:
          context.go(RoutePaths.sitterListing);
          break;
        case 2:
          context.go(RoutePaths.sitterCalendar);
          break;
        case 3:
          context.go(RoutePaths.sitterReviews);
          break;
        case 4:
          context.go(RoutePaths.profile);
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<RoleCubit>().state;
    final isOwner = role == UserRole.owner;
    final currentIndex = _calculateCurrentIndex(context, isOwner);

    final ownerItems = const [
      _NavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Ana Sayfa',
      ),
      _NavItem(
        icon: Icons.explore_outlined,
        activeIcon: Icons.explore,
        label: 'Keşfet',
      ),
      _NavItem(
        icon: Icons.pets_outlined,
        activeIcon: Icons.pets,
        label: 'Köpeklerim',
      ),
      _NavItem(
        icon: Icons.calendar_today_outlined,
        activeIcon: Icons.calendar_today,
        label: 'Taleplerim',
      ),
      _NavItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Profilim',
      ),
    ];

    final sitterItems = const [
      _NavItem(
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard,
        label: 'Talepler',
      ),
      _NavItem(
        icon: Icons.storefront_outlined,
        activeIcon: Icons.storefront,
        label: 'İlanım',
      ),
      _NavItem(
        icon: Icons.event_available_outlined,
        activeIcon: Icons.event_available,
        label: 'Takvim',
      ),
      _NavItem(
        icon: Icons.star_outline,
        activeIcon: Icons.star,
        label: 'Yorumlar',
      ),
      _NavItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Profilim',
      ),
    ];

    final items = isOwner ? ownerItems : sitterItems;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppColors.darkOutlineVariant.withValues(alpha: 0.3)
                : AppColors.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = index == currentIndex;

              final selectedColor =
                  isDark ? AppColors.darkPrimary : AppColors.primary;
              final unselectedColor = isDark
                  ? AppColors.darkOnSurfaceVariant
                  : AppColors.onSurfaceVariant;

              return Expanded(
                child: InkWell(
                  onTap: () => _onItemTapped(context, isOwner, index),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedScale(
                          scale: isSelected ? 1.1 : 1.0,
                          duration: const Duration(milliseconds: 180),
                          child: Icon(
                            isSelected ? item.activeIcon : item.icon,
                            color:
                                isSelected ? selectedColor : unselectedColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          style: isSelected
                              ? AppTypography.caption.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: selectedColor,
                                )
                              : AppTypography.caption.copyWith(
                                  color: unselectedColor,
                                ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          height: 3,
                          width: isSelected ? 14 : 0,
                          decoration: BoxDecoration(
                            color: selectedColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
