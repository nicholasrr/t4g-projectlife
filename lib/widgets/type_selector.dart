import 'package:flutter/material.dart';
import '../utils/global_data.dart';
import '../theme.dart';

/// The type selector bar showing Recurring/Ad-hoc/How-to buttons
class TypeSelector extends StatefulWidget {
  const TypeSelector({super.key});

  @override
  State<TypeSelector> createState() => _TypeSelectorState();
}

class _TypeSelectorState extends State<TypeSelector> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.padding,
        vertical: AppTheme.spacing / 2,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _TypeButton(
            icon: Icons.sync,
            label: 'Recurring',
            isSelected:
                Globals.selectedTypeNotifier.value == SelectedType.recurring,
            onTap: () => setState(() => Globals.setRecurring()),
          ),
          _TypeButton(
            icon: Icons.check_box,
            label: 'Ad-hoc',
            isSelected:
                Globals.selectedTypeNotifier.value == SelectedType.adhoc,
            onTap: () => setState(() => Globals.setAdHoc()),
          ),
          _TypeButton(
            icon: Icons.help,
            label: 'How-to',
            isSelected:
                Globals.selectedTypeNotifier.value == SelectedType.howto,
            onTap: () => setState(() => Globals.setHowTo()),
          ),
        ],
      ),
    );
  }
}

/// Individual type button with optional label
class _TypeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _TypeButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder(
      valueListenable: Globals.selectedTypeNotifier,
      builder:
          (_, selectedType, _) => InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppTheme.radius),
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacing),
              decoration: BoxDecoration(
                color:
                    isSelected ? theme.colorScheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(AppTheme.radius),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color:
                        isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.primary,
                  ),
                  if (selectedType == SelectedType.howto) ...[
                    const SizedBox(height: AppTheme.spacing / 2),
                    Text(
                      label,
                      style: theme.textTheme.labelSmall!.copyWith(
                        color:
                            isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
    );
  }
}
