import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../domain/entities/notification.dart';
import '../../../domain/entities/user_role.dart';
import '../../../domain/usecases/notification/get_notifications_use_case.dart';
import '../../../domain/usecases/notification/mark_notification_read_use_case.dart';
import '../../auth/cubit/role_cubit.dart';
import '../cubit/notifications_cubit.dart';
import '../cubit/notifications_state.dart';

/// Bildirimlerin listelendiği, filtrelendiği ve okundu işaretlendiği modal alt çekmecesi (Bottom Sheet).
class NotificationsSheet extends StatelessWidget {
  const NotificationsSheet({super.key});

  /// Modalı açan statik yardımcı metot.
  static Future<void> show(BuildContext context) {
    NotificationsCubit? existingCubit;
    try {
      existingCubit = context.read<NotificationsCubit?>();
    } catch (_) {}

    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        if (existingCubit != null) {
          return BlocProvider.value(
            value: existingCubit,
            child: const NotificationsSheet(),
          );
        }

        final repo = NotificationRepository();
        return BlocProvider(
          create: (_) => NotificationsCubit(
            getNotificationsUseCase: GetNotificationsUseCase(repo),
            markNotificationReadUseCase: MarkNotificationReadUseCase(repo),
          ),
          child: const NotificationsSheet(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<RoleCubit?>()?.state ?? UserRole.owner;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceContainer
            : AppColors.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: BlocBuilder<NotificationsCubit, NotificationsState>(
        builder: (context, state) {
          final cubit = context.read<NotificationsCubit>();
          final notifications = state.filteredNotifications;

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst çekme çubuğu
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Başlık ve Tümünü Oku Butonu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.notifications_active,
                          color: AppColors.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Bildirimler',
                            style: AppTypography.headlineSection,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (state.unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${state.unreadCount}',
                              style: AppTypography.labelTag.copyWith(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (state.hasUnread)
                        TextButton(
                          onPressed: () {
                            cubit.markAllAsRead();
                          },
                          child: Text(
                            'Tümünü Oku',
                            style: AppTypography.labelTag.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 20,
                          color: AppColors.onSurfaceVariant,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Filtreleme Çipleri — Rol Bazlı
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      context: context,
                      label: 'Tümü (${state.allNotifications.length})',
                      isSelected: state.activeFilter == NotificationFilter.all,
                      onTap: () => cubit.setFilter(NotificationFilter.all),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      context: context,
                      label: 'Okunmamış (${state.unreadCount})',
                      isSelected:
                          state.activeFilter == NotificationFilter.unread,
                      onTap: () => cubit.setFilter(NotificationFilter.unread),
                    ),
                    const SizedBox(width: 8),
                    if (role == UserRole.owner) ...[
                      _buildFilterChip(
                        context: context,
                        label: 'Aşılar',
                        isSelected:
                            state.activeFilter == NotificationFilter.vaccine,
                        onTap: () =>
                            cubit.setFilter(NotificationFilter.vaccine),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        context: context,
                        label: 'Rezervasyonlar',
                        isSelected:
                            state.activeFilter == NotificationFilter.booking,
                        onTap: () =>
                            cubit.setFilter(NotificationFilter.booking),
                      ),
                    ] else ...[
                      _buildFilterChip(
                        context: context,
                        label: 'Gelen Talepler',
                        isSelected:
                            state.activeFilter == NotificationFilter.booking,
                        onTap: () =>
                            cubit.setFilter(NotificationFilter.booking),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        context: context,
                        label: 'Misafirler & Sistem',
                        isSelected:
                            state.activeFilter == NotificationFilter.vaccine,
                        onTap: () =>
                            cubit.setFilter(NotificationFilter.vaccine),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Bildirim Listesi veya Boş Durum
              if (notifications.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 40,
                          color: isDark
                              ? AppColors.darkOnSurfaceVariant
                              : AppColors.onSurfaceVariant,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Bu filtrede bildirim bulunmuyor.',
                          style: AppTypography.bodyDefault.copyWith(
                            color: isDark
                                ? AppColors.darkOnSurfaceVariant
                                : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: notifications.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
                      return _buildNotificationCard(
                        context: context,
                        notif: notif,
                        onTap: () {
                          if (!notif.isRead) {
                            cubit.markAsRead(notif.id);
                          }
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 14),

              // Canlı Bildirim Senkronizasyon ve Hızlı İşlem Çubuğu
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceContainerHigh
                      : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkOutlineVariant.withValues(alpha: 0.6)
                        : AppColors.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_active_outlined,
                      size: 18,
                      color: isDark ? AppColors.darkPrimary : AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Canlı FCM Bildirimleri Aktif',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkOnSurface
                              : AppColors.onSurface,
                        ),
                      ),
                    ),
                    if (notifications.any((n) => !n.isRead))
                      TextButton.icon(
                        onPressed: () => cubit.markAllAsRead(),
                        icon: const Icon(Icons.done_all, size: 16),
                        label: Text(
                          'Tümünü Oku',
                          style: AppTypography.labelTag.copyWith(
                            color: isDark
                                ? AppColors.darkPrimary
                                : AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.darkPrimary : AppColors.primary)
              : (isDark
                  ? AppColors.darkSurfaceContainerHigh
                  : AppColors.surfaceContainerLow),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: AppTypography.labelTag.copyWith(
            color: isSelected
                ? (isDark ? AppColors.darkOnPrimary : Colors.white)
                : (isDark
                    ? AppColors.darkOnSurfaceVariant
                    : AppColors.onSurfaceVariant),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard({
    required BuildContext context,
    required NotificationItem notif,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    IconData icon;
    Color iconBg;

    switch (notif.type) {
      case 'booking':
        icon = Icons.calendar_month;
        iconBg = notif.isRead
            ? (isDark
                ? AppColors.darkSurfaceContainerHighest
                : AppColors.surfaceContainerHighest)
            : (isDark
                ? AppColors.darkSecondaryContainer
                : AppColors.secondaryContainer);
        break;
      case 'vaccine':
        icon = Icons.vaccines;
        iconBg = notif.isRead
            ? (isDark
                ? AppColors.darkSurfaceContainerHighest
                : AppColors.surfaceContainerHighest)
            : (isDark
                ? AppColors.darkTertiaryContainer
                : AppColors.tertiaryFixed);
        break;
      case 'walk':
        icon = Icons.directions_walk;
        iconBg = notif.isRead
            ? (isDark
                ? AppColors.darkSurfaceContainerHighest
                : AppColors.surfaceContainerHighest)
            : (isDark
                ? AppColors.darkPrimaryContainer
                : AppColors.primaryContainer);
        break;
      default:
        icon = Icons.pets;
        iconBg = notif.isRead
            ? (isDark
                ? AppColors.darkSurfaceContainerHighest
                : AppColors.surfaceContainerHighest)
            : (isDark ? AppColors.darkPrimary : AppColors.primary);
        break;
    }

    final cardBg = notif.isRead
        ? (isDark
            ? AppColors.darkSurfaceContainerHigh.withValues(alpha: 0.6)
            : AppColors.surfaceContainerLow)
        : (isDark
            ? AppColors.darkSecondaryContainer.withValues(alpha: 0.45)
            : AppColors.secondaryContainer.withValues(alpha: 0.35));

    final cardBorder = notif.isRead
        ? (isDark
            ? AppColors.darkOutlineVariant.withValues(alpha: 0.5)
            : AppColors.outlineVariant.withValues(alpha: 0.25))
        : (isDark
            ? AppColors.darkPrimary.withValues(alpha: 0.4)
            : AppColors.primary.withValues(alpha: 0.3));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(
                icon,
                size: 16,
                color: notif.isRead
                    ? (isDark
                        ? AppColors.darkOnSurfaceVariant
                        : AppColors.onSurfaceVariant)
                    : (isDark ? AppColors.darkPrimary : AppColors.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: AppTypography.titleCard.copyWith(
                            color: isDark
                                ? (notif.isRead
                                    ? AppColors.darkOnSurface.withValues(
                                        alpha: 0.85,
                                      )
                                    : AppColors.darkOnSurface)
                                : (notif.isRead
                                    ? AppColors.onSurfaceVariant
                                    : AppColors.onSurface),
                            fontWeight: notif.isRead
                                ? FontWeight.w600
                                : FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!notif.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkTertiary
                                : AppColors.tertiary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notif.body,
                    style: AppTypography.caption.copyWith(
                      color: isDark
                          ? AppColors.darkOnSurfaceVariant
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
