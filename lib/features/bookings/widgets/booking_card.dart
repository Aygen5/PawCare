import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/modals/call_modal.dart';
import '../../../core/widgets/modals/chat_modal.dart';
import '../../../core/widgets/modals/live_tracking_modal.dart';
import '../../../domain/entities/booking.dart';

/// Köpek sahibinin gönderdiği rezervasyonu gösteren ve ilgili aksiyonları içeren kart bileşeni.
class BookingCard extends StatelessWidget {
  final BookingRequest booking;
  final bool isCancelling;
  final VoidCallback? onCancel;

  const BookingCard({
    super.key,
    required this.booking,
    this.isCancelling = false,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    Color statusBg;
    Color statusColor;
    String statusText;

    switch (booking.status) {
      case BookingStatus.confirmed:
        statusBg = AppColors.successContainer;
        statusColor = AppColors.success;
        statusText = 'Onaylandı';
        break;
      case BookingStatus.pending:
        statusBg = AppColors.secondaryContainer;
        statusColor = AppColors.primary;
        statusText = 'Beklemede';
        break;
      case BookingStatus.rejected:
        statusBg = AppColors.errorContainer;
        statusColor = AppColors.error;
        statusText = 'Reddedildi';
        break;
      case BookingStatus.completed:
        statusBg = AppColors.surfaceContainerLow;
        statusColor = AppColors.onSurfaceVariant;
        statusText = 'Tamamlandı';
        break;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final dateStr =
        '${booking.startDate.day}.${booking.startDate.month}.${booking.startDate.year} - ${booking.endDate.day}.${booking.endDate.month}.${booking.endDate.year}';

    return Container(
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bakıcı Bilgisi ve Durum Rozeti
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: AssetImage(booking.sitterPhoto),
                onBackgroundImageError: (_, _) {},
                backgroundColor: AppColors.surfaceContainerLow,
                child: booking.sitterPhoto.isEmpty
                    ? const Icon(Icons.person, color: AppColors.primary)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.sitterName,
                      style: AppTypography.titleCard,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      booking.serviceTitle,
                      style: AppTypography.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statusText,
                  style: AppTypography.labelTag.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Tarih ve Not Kutusu
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceContainerLow
                  : AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_month,
                            size: 16,
                            color: isDark
                                ? AppColors.darkPrimary
                                : AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              dateStr,
                              style: AppTypography.caption.copyWith(
                                color: isDark
                                    ? AppColors.darkOnSurfaceVariant
                                    : const Color(0xFF344638),
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '₺${booking.totalPrice.toInt()}',
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.darkPrimary
                            : AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                if (booking.careNotes.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Not: ${booking.careNotes}',
                    style: AppTypography.caption.copyWith(
                      color: isDark
                          ? AppColors.darkOnSurfaceVariant
                          : AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Duruma Özel Aksiyon Butonları
          if (booking.status == BookingStatus.confirmed) ...[
            Builder(
              builder: (context) {
                final isHotel =
                    booking.serviceTitle.toLowerCase().contains('otel') ||
                    booking.sitterName.toLowerCase().contains('ayşe') ||
                    booking.sitterName.toLowerCase().contains('ayse');

                return Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => LiveTrackingModal.show(
                          context,
                          isHotel: isHotel,
                          hotelName: isHotel ? booking.sitterName : 'Mutlu Patiler Köpek Oteli',
                          locationName: 'Caddebostan, Kadıköy',
                          bookingId: booking.id,
                          sitterName: booking.sitterName,
                          dogName: booking.petName,
                        ),
                        icon: Icon(
                          isHotel ? Icons.hotel_outlined : Icons.location_on,
                          size: 16,
                        ),
                        label: Text(isHotel ? 'Otelin Konumu' : 'Canlı Takip'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => ChatModal.show(
                        context,
                        sitterName: booking.sitterName,
                        avatarPath: booking.sitterPhoto,
                      ),
                      icon: Icon(
                        Icons.chat_bubble_outline,
                        color: isDark ? AppColors.darkPrimary : AppColors.primary,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: isDark
                            ? AppColors.darkSurfaceContainerLow
                            : AppColors.surfaceContainerLow,
                        shape: const CircleBorder(),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: () => CallModal.show(
                        context,
                        contactName: booking.sitterName,
                        roleSubtitle: 'Hizmet Veren',
                        phoneNumber: '+90 532 890 12 34',
                      ),
                      icon: Icon(
                        Icons.phone_outlined,
                        color: isDark ? AppColors.darkPrimary : AppColors.primary,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: isDark
                            ? AppColors.darkSurfaceContainerLow
                            : AppColors.surfaceContainerLow,
                        shape: const CircleBorder(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ] else if (booking.status == BookingStatus.pending) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isCancelling ? null : onCancel,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: isCancelling
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Talebi İptal Et',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => ChatModal.show(
                      context,
                      sitterName: booking.sitterName,
                      avatarPath: booking.sitterPhoto,
                    ),
                    icon: Icon(
                      Icons.chat_bubble_outline,
                      size: 16,
                      color: isDark ? AppColors.darkPrimary : AppColors.primary,
                    ),
                    label: Text(
                      'Bakıcıya Yaz',
                      style: AppTypography.caption.copyWith(
                        color: isDark ? AppColors.darkPrimary : AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? AppColors.darkSurfaceContainerLow
                          : AppColors.surfaceContainerLow,
                      foregroundColor:
                          isDark ? AppColors.darkPrimary : AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => ChatModal.show(
                  context,
                  sitterName: booking.sitterName,
                  avatarPath: booking.sitterPhoto,
                ),
                icon: Icon(
                  Icons.chat_bubble_outline,
                  size: 16,
                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                ),
                label: Text(
                  'Mesaj Geçmişi',
                  style: TextStyle(
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
