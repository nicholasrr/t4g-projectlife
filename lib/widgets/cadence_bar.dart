import 'package:flutter/material.dart';
import '../theme.dart';

/// The bottom bar for selecting task cadence (D/W/M/Q/Y)
class CadenceBar extends StatelessWidget {
  final String selectedPeriodId;
  final void Function(String) onPeriodChanged;

  const CadenceBar({
    super.key,
    required this.selectedPeriodId,
    required this.onPeriodChanged,
  });

  void _onCadenceSelected(String cadence) {
    // Keep the day part of the period if possible, otherwise use current date
    final now = DateTime.now();
    final newPeriodId = switch (cadence) {
      'D' =>
        'D#${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      'W' =>
        'W#${now.year}-${now.month.toString().padLeft(2, '0')}-${(now.day - now.weekday).toString().padLeft(2, '0')}',
      'M' => 'M#${now.year}-${now.month.toString().padLeft(2, '0')}',
      'Q' => 'Q#${now.year}-${((now.month - 1) ~/ 3) + 1}',
      'Y' => 'Y#${now.year}',
      _ => selectedPeriodId,
    };
    onPeriodChanged(newPeriodId);
  }

  Widget build(BuildContext context) {
    final selectedCadence =
        selectedPeriodId.isEmpty ? 'D' : selectedPeriodId[0];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _CadenceButton(
            label: 'D',
            fullLabel: 'Day',
            isSelected: selectedCadence == 'D',
            onTap: () => _onCadenceSelected('D'),
          ),
          _CadenceButton(
            label: 'W',
            fullLabel: 'Week',
            isSelected: selectedCadence == 'W',
            onTap: () => _onCadenceSelected('W'),
          ),
          _CadenceButton(
            label: 'M',
            fullLabel: 'Month',
            isSelected: selectedCadence == 'M',
            onTap: () => _onCadenceSelected('M'),
          ),
          _CadenceButton(
            label: 'Q',
            fullLabel: 'Quarter',
            isSelected: selectedCadence == 'Q',
            onTap: () => _onCadenceSelected('Q'),
          ),
          _CadenceButton(
            label: 'Y',
            fullLabel: 'Year',
            isSelected: selectedCadence == 'Y',
            onTap: () => _onCadenceSelected('Y'),
          ),
        ],
      ),
    );
  }
}

/// Individual cadence button with expand-on-tap label
class _CadenceButton extends StatefulWidget {
  final String label;
  final String fullLabel;
  final bool isSelected;
  final VoidCallback onTap;

  const _CadenceButton({
    required this.label,
    required this.fullLabel,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_CadenceButton> createState() => _CadenceButtonState();
}

class _CadenceButtonState extends State<_CadenceButton> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.titleMedium!;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isExpanded = true),
      onTapUp: (_) {
        setState(() => _isExpanded = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isExpanded = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing,
          vertical: AppTheme.spacing / 2,
        ),
        decoration: BoxDecoration(
          color:
              widget.isSelected
                  ? theme.colorScheme.primary
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radius),
        ),
        child: Text(
          _isExpanded ? widget.fullLabel : widget.label,
          style: textStyle.copyWith(
            color:
                widget.isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
            fontWeight: widget.isSelected ? FontWeight.bold : null,
          ),
        ),
      ),
    );
  }
}
