import 'package:flutter/material.dart';
import '../theme.dart';

/// The type selector bar showing Recurring/Ad-hoc/How-to buttons
class TypeSelector extends StatefulWidget {
  const TypeSelector({super.key});

  @override
  State<TypeSelector> createState() => _TypeSelectorState();
}

class _TypeSelectorState extends State<TypeSelector> {
  bool _showLabels = false;

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
            showLabel: _showLabels,
          ),
          _TypeButton(
            icon: Icons.check_box,
            label: 'Ad-hoc',
            showLabel: _showLabels,
          ),
          _TypeButton(
            icon: Icons.help,
            label: 'How-to',
            showLabel: _showLabels,
            onTap: () => setState(() => _showLabels = !_showLabels),
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
  final bool showLabel;
  final VoidCallback? onTap;

  const _TypeButton({
    required this.icon,
    required this.label,
    required this.showLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radius),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            if (showLabel) ...[
              const SizedBox(height: AppTheme.spacing / 2),
              Text(
                label,
                style: theme.textTheme.labelSmall!.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
