import 'package:flutter/material.dart';
import '../theme.dart';
import '../db/category_repository.dart';
// category model used via repository; no direct references needed here
import '../utils/global_data.dart';

// Filter dialog and interaction: opens a dialog that lists categories with
// checkboxes, allows clearing and applying a selection. The selection is
// stored in Globals.selectedCategoryIds (ValueNotifier<Set<String>>).

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
                onPressed: () async {
                  // Load categories
                  final cats = CategoryRepository().getAllCategories();
                  // Current selection
                  final current = Set<String>.from(
                    Globals.selectedCategoryIds.value,
                  );

                  // Show dialog to pick categories
                  final result = await showDialog<Set<String>>(
                    context: context,
                    builder: (context) {
                      return StatefulBuilder(
                        builder: (context, setState) {
                          return AlertDialog(
                            title: const Text('Filter by category'),
                            content: SizedBox(
                              width: 320,
                              child:
                                  cats.isEmpty
                                      ? const Text('No categories defined')
                                      : SingleChildScrollView(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children:
                                              cats.map((c) {
                                                final isSelected = current
                                                    .contains(c.id);
                                                return CheckboxListTile(
                                                  value: isSelected,
                                                  onChanged:
                                                      (v) => setState(() {
                                                        if (v == true) {
                                                          current.add(c.id);
                                                        } else {
                                                          current.remove(c.id);
                                                        }
                                                      }),
                                                  title: Row(
                                                    children: [
                                                      Container(
                                                        width: 12,
                                                        height: 12,
                                                        margin:
                                                            const EdgeInsets.only(
                                                              right: 8,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: Color(
                                                            int.parse(
                                                              c.colorHex,
                                                            ),
                                                          ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                3,
                                                              ),
                                                        ),
                                                      ),
                                                      Text(c.title),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                        ),
                                      ),
                            ),
                            actions: [
                              TextButton(
                                onPressed:
                                    () => Navigator.pop(context, <String>{}),
                                child: const Text('Clear'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, null),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed:
                                    () => Navigator.pop(context, current),
                                child: const Text('Apply'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );

                  if (result != null) {
                    // result == empty set means clear filter
                    Globals.setSelectedCategories(result);
                  }
                },
              ),
              // show a small indicator dot when filter is active
              ValueListenableBuilder<Set<String>>(
                valueListenable: Globals.selectedCategoryIds,
                builder:
                    (_, categories, __) => Positioned(
                      right: 6,
                      top: 6,
                      child:
                          categories.isNotEmpty
                              ? Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              )
                              : const SizedBox.shrink(),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
