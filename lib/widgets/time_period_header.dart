import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projectlife/utils/utils.dart';
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
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.padding,
        vertical: AppTheme.spacing,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              onPeriodChanged(getPreviousTimePeriodId(selectedPeriodId));
            },
          ),
          Text(
            getPeriodDisplayString(selectedPeriodId),
            style: theme.textTheme.titleMedium,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              onPeriodChanged(getNextTimePeriodId(selectedPeriodId));
            },
          ),
        ],
      ),
    );
  }
}
