import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/paw_header_actions.dart';
import '../../../domain/entities/sitter.dart';
import '../cubit/provider_cubit.dart';
import '../cubit/provider_state.dart';
import '../widgets/dialogs/add_calendar_day_dialog.dart';
import '../widgets/dialogs/edit_calendar_day_dialog.dart';
import '../widgets/dialogs/edit_capacity_dialog.dart';

/// Bakıcı — Müsaitlik Takvimi Sekmesi
class SitterCalendarTab extends StatelessWidget {
  const SitterCalendarTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<ProviderCubit, ProviderState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor:
              isDark ? AppColors.darkBackground : AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Üst Başlık ve Rozetler
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Müsaitlik Takvimi',
                              style: AppTypography.headlineScreen,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Ekim 2026 • Oda Kontenjan & Doluluk',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const PawHeaderActions(),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // İstatistik Kartları (Kontenjan Güncelleme Tıklanabilir)
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Toplam Kapasite',
                          value: '${state.totalSuites} Süit',
                          icon: Icons.domain,
                          isDark: isDark,
                          onTap: () => EditCapacityDialog.show(
                            context,
                            initialTotal: state.totalSuites,
                            initialOccupied: state.occupiedSuites,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Dolu Oda',
                          value: '${state.occupiedSuites} Süit',
                          icon: Icons.pets,
                          isDark: isDark,
                          onTap: () => EditCapacityDialog.show(
                            context,
                            initialTotal: state.totalSuites,
                            initialOccupied: state.occupiedSuites,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Müsait',
                          value: '${state.availableSuites} Süit',
                          icon: Icons.check_circle_outline,
                          isDark: isDark,
                          onTap: () => EditCapacityDialog.show(
                            context,
                            initialTotal: state.totalSuites,
                            initialOccupied: state.occupiedSuites,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Günlük Doluluk Durumu & Gün Ekleme
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Günlük Doluluk Durumu',
                        style: AppTypography.headlineSection,
                      ),
                      TextButton.icon(
                        onPressed: () => AddCalendarDayDialog.show(context),
                        icon: Icon(
                          Icons.add_circle_outline,
                          size: 16,
                          color:
                              isDark ? AppColors.darkPrimary : AppColors.primary,
                        ),
                        label: Text(
                          'Gün Ekle',
                          style: AppTypography.caption.copyWith(
                            color: isDark
                                ? AppColors.darkPrimary
                                : AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  ...state.calendarDays.map((day) {
                    Color badgeColor;
                    switch (day.statusType) {
                      case CalendarDayStatusType.full:
                        badgeColor = AppColors.error;
                        break;
                      case CalendarDayStatusType.limited:
                        badgeColor = const Color(0xFFF9A825);
                        break;
                      case CalendarDayStatusType.available:
                        badgeColor =
                            isDark ? AppColors.darkPrimary : AppColors.primary;
                        break;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildCalendarDayTile(
                        day: day.day,
                        month: day.month,
                        weekday: day.weekday,
                        status: day.status,
                        badgeColor: badgeColor,
                        details: day.details,
                        isDark: isDark,
                        onTap: () => EditCalendarDayDialog.show(context, day),
                      ),
                    );
                  }),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceContainer
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow,
          border: Border.all(
            color: isDark
                ? AppColors.darkOutlineVariant
                : AppColors.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  size: 20,
                ),
                if (onTap != null)
                  Icon(
                    Icons.edit_outlined,
                    size: 13,
                    color: isDark
                        ? AppColors.darkOnSurfaceVariant
                        : AppColors.onSurfaceVariant,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: AppTypography.titleCard.copyWith(fontSize: 16)),
            const SizedBox(height: 2),
            Text(title, style: AppTypography.caption.copyWith(fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarDayTile({
    required String day,
    required String month,
    required String weekday,
    required String status,
    required Color badgeColor,
    required String details,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    final effectiveBadgeColor = (isDark && badgeColor == AppColors.primary)
        ? AppColors.darkPrimary
        : badgeColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceContainer
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppColors.cardShadow,
          border: Border.all(
            color: isDark
                ? AppColors.darkOutlineVariant
                : AppColors.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkPrimaryContainer
                    : AppColors.secondaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Text(
                    day,
                    style: AppTypography.headlineSection.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isDark
                          ? AppColors.darkOnPrimaryContainer
                          : AppColors.primary,
                    ),
                  ),
                  Text(
                    month,
                    style: AppTypography.caption.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkOnPrimaryContainer
                          : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        weekday,
                        style: AppTypography.titleCard.copyWith(fontSize: 15),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: effectiveBadgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: effectiveBadgeColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(details, style: AppTypography.caption),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark
                  ? AppColors.darkOnSurfaceVariant
                  : AppColors.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

