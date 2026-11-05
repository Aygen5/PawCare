import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/paw_header_actions.dart';
import '../../../data/repositories/firebase_booking_repository.dart';
import '../../../domain/usecases/booking/get_bookings_use_case.dart';
import '../../../domain/usecases/booking/manage_booking_status_use_case.dart';
import '../cubit/bookings_cubit.dart';
import '../cubit/bookings_state.dart';
import '../widgets/booking_card.dart';

/// Köpek sahibinin tüm rezervasyonlarını listelediği ve yönettiği ekran.
class OwnerBookingsScreen extends StatelessWidget {
  const OwnerBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      final existingCubit = context.read<BookingsCubit?>();
      if (existingCubit != null) {
        return const _OwnerBookingsView();
      }
    } catch (_) {}

    return BlocProvider(
      create: (context) {
        final bookingRepo = FirebaseBookingRepository();
        return BookingsCubit(
          getBookingsUseCase: GetBookingsUseCase(bookingRepo),
          manageBookingStatusUseCase: ManageBookingStatusUseCase(bookingRepo),
        );
      },
      child: const _OwnerBookingsView(),
    );
  }
}

class _OwnerBookingsView extends StatelessWidget {
  const _OwnerBookingsView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: BlocConsumer<BookingsCubit, BookingsState>(
          listener: (context, state) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          builder: (context, state) {
            final cubit = context.read<BookingsCubit>();
            final bookings = state.filteredBookings;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Üst Başlık ve Sağ İkonlar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rezervasyon Taleplerim',
                              style: AppTypography.headlineScreen,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Gönderdiğiniz tüm bakım ve otel talepleri',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const PawHeaderActions(),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 2. Filtreleme Çipleri
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          isDark: isDark,
                          label: 'Tümü (${state.allBookings.length})',
                          isSelected: state.activeFilter == BookingFilter.all,
                          onTap: () => cubit.setFilter(BookingFilter.all),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          isDark: isDark,
                          label: 'Bekleyen (${state.pendingCount})',
                          isSelected:
                              state.activeFilter == BookingFilter.pending,
                          onTap: () => cubit.setFilter(BookingFilter.pending),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          isDark: isDark,
                          label: 'Onaylı (${state.confirmedCount})',
                          isSelected:
                              state.activeFilter == BookingFilter.confirmed,
                          onTap: () => cubit.setFilter(BookingFilter.confirmed),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          isDark: isDark,
                          label: 'Geçmiş / Diğer',
                          isSelected: state.activeFilter == BookingFilter.past,
                          onTap: () => cubit.setFilter(BookingFilter.past),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. Rezervasyon Listesi veya Boş Durum
                  if (bookings.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 36,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceContainer
                            : AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: AppColors.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.calendar_month_outlined,
                              size: 36,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Bu filtrede rezervasyon bulunmuyor',
                            style: AppTypography.titleCard,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Keşfet sayfasına göz atarak dostunuz için uzman bir bakıcı bulabilirsiniz.',
                            style: AppTypography.caption,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton.icon(
                            onPressed: () {
                              try {
                                context.go(RoutePaths.explore);
                              } catch (_) {}
                            },
                            icon: const Icon(Icons.search, size: 18),
                            label: const Text('Bakıcıları Keşfet'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: bookings.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final b = bookings[index];
                        final isCancelling = state.cancellingBookingId == b.id;

                        return BookingCard(
                          booking: b,
                          isCancelling: isCancelling,
                          onCancel: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: isDark
                                    ? AppColors.darkSurfaceContainer
                                    : AppColors.surfaceContainerLowest,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                title: Text(
                                  'Talebi İptal Et',
                                  style: AppTypography.headlineSection,
                                ),
                                content: Text(
                                  '${b.sitterName} adlı bakıcıya gönderdiğiniz rezervasyon talebini iptal etmek istediğinize emin misiniz?',
                                  style: AppTypography.bodyDefault,
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: const Text('Vazgeç'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.error,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Evet, İptal Et'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              final success = await cubit.cancelBooking(b.id);
                              if (success) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Rezervasyon talebiniz iptal edildi.',
                                      ),
                                      backgroundColor: AppColors.primary,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                        );
                      },
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required bool isDark,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark
                    ? AppColors.darkSurfaceContainer
                    : AppColors.surfaceContainerLowest),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.outlineVariant.withValues(alpha: 0.4),
          ),
          boxShadow: isSelected ? AppColors.cardShadow : null,
        ),
        child: Text(
          label,
          style: AppTypography.labelTag.copyWith(
            color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
