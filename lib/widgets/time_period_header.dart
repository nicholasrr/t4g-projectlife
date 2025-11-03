import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme.dart';

/// Header showing current time period with navigation
class TimePeriodHeader extends StatelessWidget {
  final String selectedPeriodId;
  final void Function(String) onPeriodChanged;

  const TimePeriodHeader({
    super.key,
    required this.selectedPeriodId,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    DateTime getPeriodDate() {
      if (selectedPeriodId.isEmpty) return DateTime.now();

      final parts = selectedPeriodId.split('#')[1].split('-');
      switch (selectedPeriodId[0]) {
        case 'D':
          return DateTime(
            int.parse(parts[0]), // year
            int.parse(parts[1]), // month
            int.parse(parts[2]), // day
          );
        case 'W':
          return DateTime(
            int.parse(parts[0]), // year
            int.parse(parts[1]), // month
            int.parse(parts[2]), // day (start of week)
          );
        case 'M':
          return DateTime(int.parse(parts[0]), int.parse(parts[1]));
        case 'Q':
          final quarter = int.parse(parts[1]);
          return DateTime(int.parse(parts[0]), (quarter - 1) * 3 + 1);
        case 'Y':
          return DateTime(int.parse(parts[0]));
        default:
          return DateTime.now();
      }
    }

    String formatPeriod() {
      if (selectedPeriodId.isEmpty) return '';

      final date = getPeriodDate();
      final formatter = DateFormat('MMM d');

      switch (selectedPeriodId[0]) {
        case 'D':
          return formatter.format(date);
        case 'W':
          final weekEnd = date.add(const Duration(days: 6));
          return 'Wk ${(date.day / 7).ceil()} — ${formatter.format(date)} — ${formatter.format(weekEnd)}';
        case 'M':
          return DateFormat('MMMM yyyy').format(date);
        case 'Q':
          final quarter = (date.month - 1) ~/ 3 + 1;
          final yearQuarter = 'Q$quarter ${date.year}';
          final monthStart = DateFormat(
            'MMM',
          ).format(DateTime(date.year, (quarter - 1) * 3 + 1));
          final monthEnd = DateFormat(
            'MMM',
          ).format(DateTime(date.year, quarter * 3));
          return '$yearQuarter ($monthStart—$monthEnd)';
        case 'Y':
          return date.year.toString();
        default:
          return '';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.padding,
        vertical: AppTheme.spacing,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.onSurface.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              final date = getPeriodDate();
              final newPeriodId = switch (selectedPeriodId[0]) {
                'D' =>
                  'D#${date.subtract(const Duration(days: 1)).year}-'
                      '${date.subtract(const Duration(days: 1)).month.toString().padLeft(2, '0')}-'
                      '${date.subtract(const Duration(days: 1)).day.toString().padLeft(2, '0')}',
                'W' =>
                  'W#${date.subtract(const Duration(days: 7)).year}-'
                      '${date.subtract(const Duration(days: 7)).month.toString().padLeft(2, '0')}-'
                      '${date.subtract(const Duration(days: 7)).day.toString().padLeft(2, '0')}',
                'M' =>
                  'M#${date.month == 1 ? date.year - 1 : date.year}-'
                      '${(date.month == 1 ? 12 : date.month - 1).toString().padLeft(2, '0')}',
                'Q' =>
                  'Q#${date.month <= 3 ? date.year - 1 : date.year}-'
                      '${date.month <= 3 ? 4 : (date.month - 1) ~/ 3}',
                'Y' => 'Y#${date.year - 1}',
                _ => selectedPeriodId,
              };
              onPeriodChanged(newPeriodId);
            },
          ),
          Text(formatPeriod(), style: theme.textTheme.titleMedium),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              final date = getPeriodDate();
              final newPeriodId = switch (selectedPeriodId[0]) {
                'D' =>
                  'D#${date.add(const Duration(days: 1)).year}-'
                      '${date.add(const Duration(days: 1)).month.toString().padLeft(2, '0')}-'
                      '${date.add(const Duration(days: 1)).day.toString().padLeft(2, '0')}',
                'W' =>
                  'W#${date.add(const Duration(days: 7)).year}-'
                      '${date.add(const Duration(days: 7)).month.toString().padLeft(2, '0')}-'
                      '${date.add(const Duration(days: 7)).day.toString().padLeft(2, '0')}',
                'M' =>
                  'M#${date.month == 12 ? date.year + 1 : date.year}-'
                      '${(date.month == 12 ? 1 : date.month + 1).toString().padLeft(2, '0')}',
                'Q' =>
                  'Q#${date.month >= 10 ? date.year + 1 : date.year}-'
                      '${date.month >= 10 ? 1 : ((date.month - 1) ~/ 3) + 2}',
                'Y' => 'Y#${date.year + 1}',
                _ => selectedPeriodId,
              };
              onPeriodChanged(newPeriodId);
            },
          ),
        ],
      ),
    );
  }
}
