import '../models/category.dart';

abstract class CategoryRepository {
  Future<void> addCategory(Category category);
  List<Category> getCategories();
  Future<void> deleteCategory(String id);
  int getLinkCount(String categoryId);
}
