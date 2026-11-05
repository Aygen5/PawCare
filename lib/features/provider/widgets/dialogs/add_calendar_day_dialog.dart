import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/entities/sitter.dart';
import '../../cubit/provider_cubit.dart';

class AddCalendarDayDialog extends StatefulWidget {
  const AddCalendarDayDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<ProviderCubit>(),
        child: const AddCalendarDayDialog(),
      ),
    );
  }

  @override
  State<AddCalendarDayDialog> createState() => _AddCalendarDayDialogState();
}

class _AddCalendarDayDialogState extends State<AddCalendarDayDialog> {
  final _dayCtrl = TextEditingController(text: '28');
  final _weekdayCtrl = TextEditingController(text: 'Çarşamba');
  final _detailsCtrl = TextEditingController(
    text: 'Tüm odalar için rezervasyon kabul ediliyor',
  );

  @override
  void dispose() {
    _dayCtrl.dispose();
    _weekdayCtrl.dispose();
    _detailsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor:
          isDark ? AppColors.darkSurface : AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        'Takvime Gün Ekle',
        style: AppTypography.titleCard.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gün Numarası', style: AppTypography.caption),
            const SizedBox(height: 6),
            TextField(
              controller: _dayCtrl,
              keyboardType: TextInputType.number,
              style: AppTypography.bodyDefault,
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark
                    ? AppColors.darkSurfaceContainer
                    : AppColors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('Gün Adı', style: AppTypography.caption),
            const SizedBox(height: 6),
            TextField(
              controller: _weekdayCtrl,
              style: AppTypography.bodyDefault,
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark
                    ? AppColors.darkSurfaceContainer
                    : AppColors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('Durum Notu', style: AppTypography.caption),
            const SizedBox(height: 6),
            TextField(
              controller: _detailsCtrl,
              style: AppTypography.bodyDefault,
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark
                    ? AppColors.darkSurfaceContainer
                    : AppColors.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'İptal',
            style: TextStyle(
              color: isDark
                  ? AppColors.darkOnSurfaceVariant
                  : AppColors.onSurfaceVariant,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            final day = _dayCtrl.text.trim();
            if (day.isNotEmpty) {
              final newDay = SitterCalendarDay(
                id: 'cal_${DateTime.now().millisecondsSinceEpoch}',
                day: day,
                month: 'Eki',
                weekday: _weekdayCtrl.text.trim(),
                status: 'Tamamen Müsait',
                statusType: CalendarDayStatusType.available,
                details: _detailsCtrl.text.trim(),
              );
              context.read<ProviderCubit>().addCalendarDay(newDay);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '$day Ekim (${_weekdayCtrl.text.trim()}) takvime eklendi!',
                  ),
                  backgroundColor:
                      isDark ? AppColors.darkPrimary : AppColors.primary,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? AppColors.darkPrimary : AppColors.primary,
            foregroundColor:
                isDark ? AppColors.darkOnPrimary : AppColors.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Ekle'),
        ),
      ],
    );
  }
}

