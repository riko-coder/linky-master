import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/category.dart';
import '../models/link_item.dart';

class HiveService {
  static const String _categoriesBox = 'categories';
  static const String _linksBox = 'links';

  static late Box<Category> _categoriesBoxInstance;
  static late Box<LinkItem> _linksBoxInstance;

  static Box<Category> get categoriesBox => _categoriesBoxInstance;
  static Box<LinkItem> get linksBox => _linksBoxInstance;

  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(CategoryAdapter());
    Hive.registerAdapter(LinkItemAdapter());

    _categoriesBoxInstance = await Hive.openBox<Category>(_categoriesBox);
    _linksBoxInstance = await Hive.openBox<LinkItem>(_linksBox);

    await _seedDummyData();
  }

  /// Refresh data from disk - call this when app resumes
  static Future<void> refresh() async {
    try {
      // Close and reopen the boxes to force reload from disk
      await Future.wait([
        _categoriesBoxInstance.close(),
        _linksBoxInstance.close(),
      ]);
      
      // Reopen the boxes
      _categoriesBoxInstance = await Hive.openBox<Category>(_categoriesBox);
      _linksBoxInstance = await Hive.openBox<LinkItem>(_linksBox);
    } catch (e) {
      print('Error refreshing Hive boxes: $e');
    }
  }

  static Future<void> _seedDummyData() async {
    if (_categoriesBoxInstance.isEmpty) {
      final categories = [
        Category(id: '1', name: 'Cooking'),
        Category(id: '2', name: 'Study'),
        Category(id: '3', name: 'Finance'),
      ];

      for (final category in categories) {
        await _categoriesBoxInstance.put(category.id, category);
      }

      final links = [
        LinkItem(
          id: '1',
          title: 'YouTube Recipe',
          url: 'https://youtube.com',
          categoryId: '1',
          createdAt: DateTime.now(),
        ),
        LinkItem(
          id: '2',
          title: 'Cooking Blog',
          url: 'https://cookingblog.com',
          categoryId: '1',
          createdAt: DateTime.now(),
        ),
        LinkItem(
          id: '3',
          title: 'Online Courses',
          url: 'https://coursera.org',
          categoryId: '2',
          createdAt: DateTime.now(),
        ),
        LinkItem(
          id: '4',
          title: 'Finance Tips',
          url: 'https://financeblog.com',
          categoryId: '3',
          createdAt: DateTime.now(),
        ),
      ];

      for (final link in links) {
        await _linksBoxInstance.put(link.id, link);
      }
    }
  }

  static List<Category> getCategories() {
    return _categoriesBoxInstance.values.toList();
  }

  static Future<void> addCategory(Category category) async {
    await _categoriesBoxInstance.put(category.id, category);
    // Force flush to disk
    await _categoriesBoxInstance.flush();
  }

  static Future<void> deleteCategory(String id) async {
    await _categoriesBoxInstance.delete(id);
    await _categoriesBoxInstance.flush();
    final linksToDelete = _linksBoxInstance.values
        .where((link) => link.categoryId == id)
        .map((link) => link.id)
        .toList();
    for (final linkId in linksToDelete) {
      await _linksBoxInstance.delete(linkId);
    }
    await _linksBoxInstance.flush();
  }

  static List<LinkItem> getLinksByCategory(String categoryId) {
    return _linksBoxInstance.values
        .where((link) => link.categoryId == categoryId)
        .toList();
  }

  static List<LinkItem> getAllLinks() {
    return _linksBoxInstance.values.toList();
  }

  static int getLinkCount(String categoryId) {
    return _linksBoxInstance.values
        .where((link) => link.categoryId == categoryId)
        .length;
  }

  static Future<void> addLink(LinkItem link) async {
    await _linksBoxInstance.put(link.id, link);
    // Force flush to disk
    await _linksBoxInstance.flush();
  }

  static Future<void> deleteLink(String id) async {
    await _linksBoxInstance.delete(id);
    // Force flush to disk
    await _linksBoxInstance.flush();
  }

  /// Export all data as JSON string
  static String exportDataAsJson() {
    final categories = _categoriesBoxInstance.values
        .map((c) => {
          'id': c.id,
          'name': c.name,
        })
        .toList();

    final links = _linksBoxInstance.values
        .map((l) => {
          'id': l.id,
          'title': l.title,
          'url': l.url,
          'categoryId': l.categoryId,
          'createdAt': l.createdAt.toIso8601String(),
        })
        .toList();

    final data = {
      'version': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'categories': categories,
      'links': links,
    };

    return jsonEncode(data);
  }

  /// Import data from JSON string, merging with existing data
  /// If merge is true, new data is merged with existing data (new items added, existing not overwritten)
  /// If merge is false, existing data is cleared first
  static Future<void> importDataFromJson(String jsonString,
      {bool merge = true}) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      if (!merge) {
        // Clear existing data if not merging
        await _categoriesBoxInstance.clear();
        await _linksBoxInstance.clear();
      }

      // Import categories
      final categories = data['categories'] as List<dynamic>? ?? [];
      for (final catData in categories) {
        final category = Category(
          id: catData['id'] as String,
          name: catData['name'] as String,
        );
        // Only add if not already exists (preserves existing data)
        if (!_categoriesBoxInstance.containsKey(category.id)) {
          await _categoriesBoxInstance.put(category.id, category);
        }
      }

      // Import links
      final links = data['links'] as List<dynamic>? ?? [];
      for (final linkData in links) {
        final link = LinkItem(
          id: linkData['id'] as String,
          title: linkData['title'] as String,
          url: linkData['url'] as String,
          categoryId: linkData['categoryId'] as String,
          createdAt: DateTime.parse(linkData['createdAt'] as String),
        );
        // Only add if not already exists (preserves existing data)
        if (!_linksBoxInstance.containsKey(link.id)) {
          await _linksBoxInstance.put(link.id, link);
        }
      }
    } catch (e) {
      throw Exception('Failed to import data: $e');
    }
  }
}
