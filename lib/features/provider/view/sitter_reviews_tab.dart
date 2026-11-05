import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/paw_header_actions.dart';

/// Bakıcı — Değerlendirmeler & Puanlar Sekmesi
class SitterReviewsTab extends StatelessWidget {
  const SitterReviewsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
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
                          'Değerlendirmelerim',
                          style: AppTypography.headlineScreen,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '128 Köpek Sahibinin Gerçek Deneyimi',
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

              // Puan Özeti Kahraman Kartı
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceContainer
                      : AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: AppColors.cardShadow,
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkOutlineVariant
                        : AppColors.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Column(
                      children: [
                        Text(
                          '4.9',
                          style: AppTypography.headlineHero.copyWith(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? AppColors.darkPrimary
                                : AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: List.generate(
                            5,
                            (index) => const Icon(
                              Icons.star,
                              color: Color(0xFFF9A825),
                              size: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '128 Değerlendirme',
                          style: AppTypography.caption.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        children: [
                          _buildRatingBar('Temizlik & Hijyen', 0.98, '5.0', isDark),
                          const SizedBox(height: 6),
                          _buildRatingBar('İletişim & Güven', 0.96, '4.9', isDark),
                          const SizedBox(height: 6),
                          _buildRatingBar('Oyun & İlgilenme', 0.97, '4.9', isDark),
                          const SizedBox(height: 6),
                          _buildRatingBar('Veteriner & Bakım', 0.94, '4.8', isDark),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Son Kullanıcı Yorumları',
                style: AppTypography.headlineSection,
              ),
              const SizedBox(height: 12),

              _buildReviewCard(
                authorName: 'Aygen Y.',
                dogName: 'Barley (Golden Retriever)',
                timeAgo: '3 gün önce',
                rating: 5.0,
                comment:
                    'Ayşe Hanım gerçekten inanılmaz bir bakıcı! Barley 2 gece kaldı, her gün fotoğraf ve video gönderdi. İlaç saatlerini ve tavuk alerjisini harfiyen uyguladı. Çok teşekkürler!',
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildReviewCard(
                authorName: 'Selin Bulut',
                dogName: 'Rüzgar (Siberian Husky)',
                timeAgo: '1 hafta önce',
                rating: 5.0,
                comment:
                    'Tertemiz bir ortam, geniş bahçe alanı ve çok ilgili yaklaşım. Rüzgar eve dönerken neredeyse ayrılmak istemedi!',
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildReviewCard(
                authorName: 'Emre Kaya',
                dogName: 'Max (Beagle)',
                timeAgo: '2 hafta önce',
                rating: 4.8,
                comment:
                    'İletişim çok hızlı ve detaylıydı. Güler yüzlü ve işini severek yapan bir bakıcı. Teşekkürler Ayşe Hanım.',
                isDark: isDark,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingBar(
    String label,
    double ratio,
    String score,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.caption.copyWith(fontSize: 11)),
            Text(
              score,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 3),
        LinearProgressIndicator(
          value: ratio,
          backgroundColor: isDark
              ? AppColors.darkSurfaceContainerLow
              : AppColors.surfaceContainerLow,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          borderRadius: BorderRadius.circular(4),
          minHeight: 6,
        ),
      ],
    );
  }

  Widget _buildReviewCard({
    required String authorName,
    required String dogName,
    required String timeAgo,
    required double rating,
    required String comment,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(authorName, style: AppTypography.titleCard),
                  const SizedBox(height: 2),
                  Text(
                    dogName,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Color(0xFFF9A825),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeAgo,
                    style: AppTypography.caption.copyWith(fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(comment, style: AppTypography.bodyDefault),
        ],
      ),
    );
  }
}

