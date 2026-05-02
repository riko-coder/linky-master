import '../models/category.dart';
import '../storage/hive_service.dart';
import 'category_repository.dart';

class LocalCategoryRepository implements CategoryRepository {
  @override
  Future<void> addCategory(Category category) async {
    await HiveService.addCategory(category);
  }

  @override
  List<Category> getCategories() {
    return HiveService.getCategories();
  }

  @override
  Future<void> deleteCategory(String id) async {
    await HiveService.deleteCategory(id);
  }

  @override
  int getLinkCount(String categoryId) {
    return HiveService.getLinkCount(categoryId);
  }
}
