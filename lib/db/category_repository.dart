import 'package:hive/hive.dart';
import '../models/category.dart';
import 'hive_boxes.dart';

/// Repository for managing categories in Hive storage.
class CategoryRepository {
  final Box _categoriesBox;

  CategoryRepository() : _categoriesBox = Hive.box(categoriesBoxName);

  /// Creates a new category.
  Future<void> createCategory(Category category) async {
    await _categoriesBox.put(category.id, category);
  }

  /// Gets a category by ID.
  Category? getCategory(String id) {
    return _categoriesBox.get(id);
  }

  /// Gets all categories.
  List<Category> getAllCategories() {
    return _categoriesBox.values.cast<Category>().toList();
  }

  /// Updates an existing category.
  Future<void> editCategory(Category category) async {
    if (!_categoriesBox.containsKey(category.id)) {
      throw StateError('Cannot edit non-existent category: ${category.id}');
    }
    await _categoriesBox.put(category.id, category);
  }

  /// Deletes a category.
  Future<void> deleteCategory(String id) async {
    await _categoriesBox.delete(id);
  }

  /// Creates multiple categories at once.
  Future<void> createCategories(List<Category> categories) async {
    await _categoriesBox.putAll(
      Map.fromEntries(categories.map((c) => MapEntry(c.id, c))),
    );
  }
}
