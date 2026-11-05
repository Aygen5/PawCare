import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/entities/sitter.dart';
import '../../cubit/provider_cubit.dart';

class EditCalendarDayDialog extends StatefulWidget {
  final SitterCalendarDay day;

  const EditCalendarDayDialog({super.key, required this.day});

  static Future<void> show(BuildContext context, SitterCalendarDay day) {
    return showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<ProviderCubit>(),
        child: EditCalendarDayDialog(day: day),
      ),
    );
  }

  @override
  State<EditCalendarDayDialog> createState() => _EditCalendarDayDialogState();
}

class _EditCalendarDayDialogState extends State<EditCalendarDayDialog> {
  late String _selectedStatus;
  late CalendarDayStatusType _selectedType;
  late final TextEditingController _detailsCtrl;

  final _options = const [
    ('Tamamen Müsait', CalendarDayStatusType.available),
    ('1 Oda Müsait', CalendarDayStatusType.limited),
    ('2 Oda Müsait', CalendarDayStatusType.limited),
    ('3 Oda Müsait', CalendarDayStatusType.available),
    ('Dolu (Tüm Odalar)', CalendarDayStatusType.full),
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.day.status;
    _selectedType = widget.day.statusType;
    _detailsCtrl = TextEditingController(text: widget.day.details);
  }

  @override
  void dispose() {
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
        '${widget.day.day} ${widget.day.month} (${widget.day.weekday}) Müsaitliği',
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
            Text('Durum Seçin', style: AppTypography.caption),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _options.map((opt) {
                final isSelected = _selectedStatus == opt.$1;
                return ChoiceChip(
                  label: Text(opt.$1),
                  selected: isSelected,
                  selectedColor: isDark
                      ? AppColors.darkPrimaryContainer
                      : AppColors.secondaryContainer,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? (isDark
                            ? AppColors.darkPrimary
                            : AppColors.primary)
                        : (isDark
                            ? AppColors.darkOnSurface
                            : AppColors.onSurface),
                  ),
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _selectedStatus = opt.$1;
                        _selectedType = opt.$2;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text('Rezervasyon / Not Detayı', style: AppTypography.caption),
            const SizedBox(height: 6),
            TextField(
              controller: _detailsCtrl,
              maxLines: 2,
              style: AppTypography.bodyDefault,
              decoration: InputDecoration(
                hintText: 'Misafir veya oda notlarını yazın',
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
            final updated = widget.day.copyWith(
              status: _selectedStatus,
              statusType: _selectedType,
              details: _detailsCtrl.text.trim().isEmpty
                  ? 'Rezervasyon durumu güncellendi'
                  : _detailsCtrl.text.trim(),
            );
            context.read<ProviderCubit>().updateCalendarDay(updated);
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${widget.day.day} ${widget.day.month} müsaitlik durumu "$_selectedStatus" olarak güncellendi!',
                ),
                backgroundColor:
                    isDark ? AppColors.darkPrimary : AppColors.primary,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? AppColors.darkPrimary : AppColors.primary,
            foregroundColor:
                isDark ? AppColors.darkOnPrimary : AppColors.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Güncelle'),
        ),
      ],
    );
  }
}

