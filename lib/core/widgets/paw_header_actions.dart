import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/route_names.dart';
import '../../features/notifications/cubit/notifications_cubit.dart';
import '../../features/notifications/view/notifications_sheet.dart';
import '../theme/app_colors.dart';

/// Ekranların sağ üst köşesinde profil ve bildirim rozetini sunan standart eylem bileşeni.
class PawHeaderActions extends StatelessWidget {
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final bool showProfile;

  const PawHeaderActions({
    super.key,
    this.onNotificationTap,
    this.onProfileTap,
    this.showProfile = true,
  });

  void _handleNotificationTap(BuildContext context) {
    if (onNotificationTap != null) {
      onNotificationTap!();
      return;
    }
    NotificationsSheet.show(context);
  }

  void _handleProfileTap(BuildContext context) {
    if (onProfileTap != null) {
      onProfileTap!();
      return;
    }
    try {
      context.go(RoutePaths.profile);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notifState = context.watch<NotificationsCubit?>()?.state;
    final unreadCount = notifState?.unreadCount ?? 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bildirim ikonu ve okunmamış rozet
        InkWell(
          onTap: () => _handleNotificationTap(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceContainer
                  : AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? AppColors.darkOutlineVariant.withValues(alpha: 0.5)
                    : AppColors.outlineVariant.withValues(alpha: 0.4),
              ),
              boxShadow: AppColors.cardShadow,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.notifications_outlined,
                  size: 20,
                  color: isDark ? AppColors.darkSecondary : AppColors.secondary,
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.tertiary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (showProfile) ...[
          const SizedBox(width: 10),
          // Profil ikonu
          InkWell(
            onTap: () => _handleProfileTap(context),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceContainer
                    : AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkOutlineVariant.withValues(alpha: 0.5)
                      : AppColors.outlineVariant.withValues(alpha: 0.4),
                ),
                boxShadow: AppColors.cardShadow,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.person_outline,
                size: 22,
                color: isDark ? AppColors.darkPrimary : AppColors.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
