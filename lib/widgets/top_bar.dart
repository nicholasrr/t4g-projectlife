import 'package:flutter/material.dart';
import '../theme.dart';

/// Top bar with engine/settings button, filter button
class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.padding,
        vertical: AppTheme.spacing,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Engine/Settings button
          IconButton(
            icon: const Icon(AppTheme.engineIcon),
            onPressed: () {
              // TODO: Show settings
            },
          ),

          // Filter button with optional active indicator
          Stack(
            children: [
              IconButton(
                icon: const Icon(AppTheme.filterIcon),
                onPressed: () {
                  // TODO: Show filter options
                },
              ),
              // TODO: Show dot when filter is active
            ],
          ),
        ],
      ),
    );
  }
}
