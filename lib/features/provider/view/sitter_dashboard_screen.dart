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
import '../../auth/cubit/role_cubit.dart';
import '../../../core/widgets/modals/call_modal.dart';
import '../../../core/widgets/modals/chat_modal.dart';
import '../../../core/widgets/modals/live_tracking_modal.dart';
import '../cubit/provider_cubit.dart';
import '../cubit/provider_state.dart';
import '../widgets/booking_request_card.dart';

/// Hizmet veren (sitter) kontrol ve yönetim paneli ekranı.
class SitterDashboardScreen extends StatelessWidget {
  final ProviderCubit? cubit;

  const SitterDashboardScreen({super.key, this.cubit});

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider.value(
        value: cubit!,
        child: const _SitterDashboardView(),
      );
    }

    // Mevcut bir ProviderCubit varsa onu kullanır (test ve üst sarmalayıcı desteği)
    try {
      final existingCubit = context.read<ProviderCubit?>();
      if (existingCubit != null) {
        return const _SitterDashboardView();
      }
    } catch (_) {}

    return BlocProvider(
      create: (context) {
        final bookingRepo = FirebaseBookingRepository();
        return ProviderCubit(
          getBookingsUseCase: GetBookingsUseCase(bookingRepo),
          manageBookingStatusUseCase: ManageBookingStatusUseCase(bookingRepo),
        );
      },
      child: const _SitterDashboardView(),
    );
  }
}

class _SitterDashboardView extends StatelessWidget {
  const _SitterDashboardView();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: BlocConsumer<ProviderCubit, ProviderState>(
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
            final cubit = context.read<ProviderCubit>();
            final pendingBookings = state.pendingBookings;
            final confirmedBookings = state.confirmedBookings;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                              'Hizmet Veren Paneli',
                              style: AppTypography.headlineScreen,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Bugünün Özeti & Talepler',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Bildirim ve Profil Açılır Menüsü
                      const PawHeaderActions(),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 2. Bakıcı Profil Kartı & Rol Değiştirme Butonu
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceContainer
                          : AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppColors.cardShadow,
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 24,
                          backgroundImage: AssetImage('assets/images/ayse.jpg'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Ayşe Yılmaz',
                                      style: AppTypography.headlineSection,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.verified,
                                    size: 16,
                                    color: isDark
                                        ? AppColors.darkPrimary
                                        : AppColors.primary,
                                  ),
                                ],
                              ),
                              Text(
                                'Mutlu Patiler Köpek Oteli',
                                style: AppTypography.caption,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Rol Değiştir: Sahip Moduna Geç
                        OutlinedButton.icon(
                          onPressed: () {
                            context.read<RoleCubit?>()?.switchToOwner();
                            try {
                              context.go(RoutePaths.home);
                            } catch (_) {}
                          },
                          icon: Icon(
                            Icons.swap_horiz,
                            size: 16,
                            color: isDark
                                ? AppColors.darkPrimary
                                : AppColors.primary,
                          ),
                          label: Text(
                            'Sahip Modu',
                            style: AppTypography.labelTag.copyWith(
                              color: isDark
                                  ? AppColors.darkPrimary
                                  : AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isDark
                                  ? AppColors.darkPrimary
                                  : AppColors.primary,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 3. KPI Metrik Kartları
                  Row(
                    children: [
                      _buildMetricCard(
                        'Bekleyen',
                        '${pendingBookings.length}',
                        'Talep',
                        isDark
                            ? AppColors.darkSecondaryContainer
                            : AppColors.secondaryContainer,
                        isDark ? AppColors.darkPrimary : AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      _buildMetricCard(
                        'Onaylı',
                        '${confirmedBookings.length}',
                        'Rezervasyon',
                        isDark
                            ? AppColors.darkTertiaryContainer
                            : AppColors.tertiaryFixed,
                        isDark ? AppColors.darkTertiary : AppColors.tertiary,
                      ),
                      const SizedBox(width: 10),
                      _buildMetricCard(
                        'Kazanç',
                        '₺${state.totalEarnings.toInt()}',
                        'Bu ay',
                        isDark
                            ? AppColors.darkSurfaceContainerLow
                            : AppColors.surfaceContainerLow,
                        isDark ? AppColors.darkOnSurface : AppColors.onSurface,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 4. Yeni Gelen Rezervasyon Talepleri
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Yeni Gelen Talepler',
                        style: AppTypography.headlineSection,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: pendingBookings.isNotEmpty
                              ? AppColors.primary
                              : AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${pendingBookings.length}',
                          style: AppTypography.labelTag.copyWith(
                            color: pendingBookings.isNotEmpty
                                ? Colors.white
                                : AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (pendingBookings.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceContainer
                            : AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.task_alt,
                            color: AppColors.success,
                            size: 36,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Tüm talepler yanıtlandı!',
                            style: AppTypography.titleCard,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Şu anda bekleyen yeni rezervasyon talebi bulunmuyor.',
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: pendingBookings.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final booking = pendingBookings[index];
                        final isUpdating =
                            state.updatingBookingId == booking.id;

                        return BookingRequestCard(
                          booking: booking,
                          isUpdating: isUpdating,
                          onConfirm: () async {
                            final success = await cubit.confirmBooking(
                              booking.id,
                            );
                            if (success) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${booking.petName} için rezervasyon başarıyla onaylandı! 🐾',
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: AppColors.primary,
                                  ),
                                );
                              }
                            }
                          },
                          onReject: () async {
                            final success = await cubit.rejectBooking(
                              booking.id,
                            );
                            if (success) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${booking.petName} rezervasyon talebi reddedildi.',
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          },
                        );
                      },
                    ),
                  const SizedBox(height: 24),

                  // 5. Aktif & Yaklaşan Konuklar
                  Text(
                    'Aktif & Yaklaşan Konuklar',
                    style: AppTypography.headlineSection,
                  ),
                  const SizedBox(height: 12),

                  if (confirmedBookings.isNotEmpty)
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: confirmedBookings.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final confirmed = confirmedBookings[index];
                        return _buildGuestCard(
                          context,
                          bookingId: confirmed.id,
                          petName: confirmed.petName,
                          breed: confirmed.petBreed,
                          service: confirmed.serviceTitle,
                          avatarPath: 'assets/images/barley.jpg',
                          statusBadge: 'Onaylandı',
                        );
                      },
                    )
                  else
                    _buildGuestCard(
                      context,
                      bookingId: 'demo_booking_caddebostan',
                      petName: 'Barley',
                      breed: 'Golden Retriever',
                      service: 'Oda: Süit 3 • 2 Gece Konaklama',
                      avatarPath: 'assets/images/barley.jpg',
                      statusBadge: 'Giriş Yapıldı',
                    ),
                  const SizedBox(height: 24),

                  // 6. Hızlı Yönetim Seçenekleri
                  Text('Hızlı Yönetim', style: AppTypography.headlineSection),
                  const SizedBox(height: 12),
                  _buildActionTile(
                    context,
                    icon: Icons.storefront_outlined,
                    title: 'İlanımı ve Fiyatlarımı Düzenle',
                    subtitle: 'Gecelik ücret, fotoğraflar ve olanaklar',
                    onTap: () {
                      context.go(RoutePaths.sitterListing);
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildActionTile(
                    context,
                    icon: Icons.calendar_month_outlined,
                    title: 'Müsaitlik Takvimini Güncelle',
                    subtitle: 'Dolu günler ve oda kontenjanları',
                    onTap: () {
                      context.go(RoutePaths.sitterCalendar);
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildActionTile(
                    context,
                    icon: Icons.star_outline,
                    title: 'Değerlendirmelerim & Puanlar',
                    subtitle: '4.9 ortalama puan (128 yorum)',
                    onTap: () {
                      context.go(RoutePaths.sitterReviews);
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

  Widget _buildGuestCard(
    BuildContext context, {
    required String bookingId,
    required String petName,
    required String breed,
    required String service,
    required String avatarPath,
    required String statusBadge,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurfaceContainer
            : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppColors.cardShadow,
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 24, backgroundImage: AssetImage(avatarPath)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Text(petName, style: AppTypography.titleCard),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.successContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusBadge,
                        style: AppTypography.labelTag.copyWith(
                          color: AppColors.success,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  service,
                  style: AppTypography.caption,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.navigation_outlined,
              color: isDark ? AppColors.darkPrimary : AppColors.primary,
            ),
            tooltip: 'GPS Yürüyüşünü Başlat / Yönet',
            onPressed: () => LiveTrackingModal.show(
              context,
              bookingId: bookingId,
              sitterName: 'Mert (Gezdirici)',
              dogName: petName,
              isSitterMode: true,
            ),
            style: IconButton.styleFrom(
              backgroundColor: isDark
                  ? AppColors.darkSurfaceContainerLow
                  : AppColors.surfaceContainerLow,
              shape: const CircleBorder(),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: Icon(
              Icons.phone_outlined,
              color: isDark ? AppColors.darkPrimary : AppColors.primary,
            ),
            onPressed: () => CallModal.show(
              context,
              contactName: 'Aygen ($petName Sahibi)',
              roleSubtitle: 'Kayıtlı İletişim Numarası',
              phoneNumber: '+90 532 890 12 34',
            ),
            style: IconButton.styleFrom(
              backgroundColor: isDark
                  ? AppColors.darkSurfaceContainerLow
                  : AppColors.surfaceContainerLow,
              shape: const CircleBorder(),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: Icon(
              Icons.chat_bubble_outline,
              color: isDark ? AppColors.darkPrimary : AppColors.primary,
            ),
            onPressed: () => ChatModal.show(
              context,
              sitterName: 'Aygen (Köpek Sahibi)',
              avatarPath: avatarPath,
            ),
            style: IconButton.styleFrom(
              backgroundColor: isDark
                  ? AppColors.darkSurfaceContainerLow
                  : AppColors.surfaceContainerLow,
              shape: const CircleBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String subtitle,
    Color bgColor,
    Color textColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.caption,
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: AppTypography.headlineSection.copyWith(
                color: textColor,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(subtitle, style: AppTypography.caption.copyWith(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          border: Border.all(
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceContainerLow
                    : AppColors.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isDark ? AppColors.darkPrimary : AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.titleCard),
                  Text(subtitle, style: AppTypography.caption),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: isDark
                  ? AppColors.darkOnSurfaceVariant
                  : AppColors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
