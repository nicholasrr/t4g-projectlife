import 'package:flutter/material.dart';
import '../db/category_repository.dart';
import '../models/category.dart';
import '../theme.dart';
import '../utils/global_data.dart';

/// Screen to create, edit and delete categories.
class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  final _repo = CategoryRepository();
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() => _categories = _repo.getAllCategories());
  }

  Future<void> _showEditDialog({Category? existing}) async {
    final titleCtl = TextEditingController(text: existing?.title ?? '');
    String selectedColor = existing?.colorHex ?? '0xFF90CAF9';

    await showDialog<void>(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text(
                    existing != null ? 'Edit category' : 'New category',
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleCtl,
                        decoration: const InputDecoration(labelText: 'Title'),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final hex in [
                            '0xFFEF9A9A',
                            '0xFFF48FB1',
                            '0xFFCE93D8',
                            '0xFF9FA8DA',
                            '0xFF90CAF9',
                            '0xFF80DEEA',
                            '0xFFA5D6A7',
                            '0xFFFFF59D',
                            '0xFFFFE082',
                          ])
                            GestureDetector(
                              onTap: () => setState(() => selectedColor = hex),
                              child: Container(
                                width: 36,
                                height: 36,
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  color: Color(int.parse(hex)),
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(
                                    color:
                                        selectedColor == hex
                                            ? Colors.black
                                            : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final title = titleCtl.text.trim();
                        if (title.isEmpty) return;
                        if (existing != null) {
                          final updated = Category(
                            id: existing.id,
                            title: title,
                            colorHex: selectedColor,
                          );
                          await _repo.editCategory(updated);
                        } else {
                          final id =
                              DateTime.now().microsecondsSinceEpoch.toString();
                          final cat = Category(
                            id: id,
                            title: title,
                            colorHex: selectedColor,
                          );
                          await _repo.createCategory(cat);
                        }
                        _load();
                        Navigator.pop(context);
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _deleteCategory(Category c) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete category?'),
            content: const Text(
              'This will remove the category from any tasks. Tasks that are currently loaded will be updated to become uncategorized.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await _repo.deleteCategory(c.id);
      // Remove from active filters if present
      final newSet = Set<String>.from(Globals.selectedCategoryIds.value);
      newSet.remove(c.id);
      Globals.setSelectedCategories(newSet);
      // Bump tasksVersion so loaded task lists will reload and TaskRepository
      // will clear category references for tasks in visible periods.
      Globals.tasksVersion.value++;
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showEditDialog(),
            tooltip: 'New category',
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppTheme.padding),
        itemBuilder: (context, index) {
          final c = _categories[index];
          return ListTile(
            leading: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Color(int.parse(c.colorHex)),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            title: Text(c.title),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditDialog(existing: c),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteCategory(c),
                ),
              ],
            ),
          );
        },
        separatorBuilder: (_, __) => const Divider(),
        itemCount: _categories.length,
      ),
    );
  }
}
