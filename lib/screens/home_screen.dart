import 'dart:async';
import 'package:flutter/material.dart';
import '../models/category.dart';
import '../storage/hive_service.dart';
import '../utils/app_colors.dart';
import '../utils/search_utils.dart';
import '../widgets/category_card.dart';
import '../repositories/local_category_repository.dart';
import '../repositories/category_repository.dart';
import 'category_screen.dart';
import 'add_link_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final String? initialUrl;
  final VoidCallback? onShareUrlHandled;

  const HomeScreen({super.key, this.initialUrl, this.onShareUrlHandled});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final CategoryRepository _categoryRepository = LocalCategoryRepository();
  List<Category> _categories = [];
  List<Category> _filteredCategories = [];
  String _searchQuery = '';
  StreamSubscription? _linksSubscription;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCategories();
    _searchController.addListener(_updateSearch);
    // Listen for changes in the links box to auto-refresh categories
    _linksSubscription = HiveService.linksBox.watch().listen((_) {
      if (mounted) {
        _loadCategories();
      }
    });
    if (widget.initialUrl != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToAddLink(widget.initialUrl!);
        widget.onShareUrlHandled?.call();
      });
    }
  }

  void _updateSearch() {
    final query = _searchController.text;
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredCategories = _categories;
      } else {
        _filteredCategories = SearchUtils.searchAndSort(
          query,
          _categories,
          (category) => category.name,
        );
      }
    });
  }

  void _loadCategories() {
    setState(() {
      _categories = _categoryRepository.getCategories();
      _filteredCategories = _categories;
    });
  }

  Future<void> _onRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    // Refresh Hive boxes from disk first
    await HiveService.refresh();
    _loadCategories();
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  void _navigateToAddLink([String? url]) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddLinkScreen(initialUrl: url)),
    ).then((_) {
      _loadCategories();
      _updateSearch();
    });
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(
          controller: _categoryController,
          decoration: const InputDecoration(
            hintText: 'Enter category name',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _categoryController.clear();
            },
            child: const Text('Cancel'),
          ),
          TextButton(onPressed: _addCategory, child: const Text('Save')),
        ],
      ),
    );
  }

  void _addCategory() async {
    final name = _categoryController.text.trim();
    if (name.isNotEmpty) {
      final category = Category(id: DateTime.now().toString(), name: name);
      await _categoryRepository.addCategory(category);
      _loadCategories();
      _updateSearch();
      if (mounted) {
        Navigator.of(context).pop();
        _categoryController.clear();
      }
    }
  }

  void _deleteCategory(Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Are you sure you want to delete "${category.name}" and all its links?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await _categoryRepository.deleteCategory(category.id);
              _loadCategories();
              if (mounted) navigator.pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came back to foreground - refresh Hive and reload data
      HiveService.refresh().then((_) {
        if (mounted) {
          _loadCategories();
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _categoryController.dispose();
    _searchController.dispose();
    _linksSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Linky'),
        actions: [
          IconButton(
            icon: const Icon(Icons.link),
            onPressed: () => _navigateToAddLink(),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search categories...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          // Categories List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: Stack(
                children: [
                  _filteredCategories.isEmpty
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Center(
                            child: Text(
                              _searchQuery.isEmpty
                                  ? 'No categories yet'
                                  : 'No categories found',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredCategories.length,
                          itemBuilder: (context, index) {
                            final category = _filteredCategories[index];
                            return Dismissible(
                              key: Key(category.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 16),
                                color: Colors.red,
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              confirmDismiss: (direction) async {
                                return await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Category'),
                                    content: Text(
                                      'Are you sure you want to delete "${category.name}" and all its links?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              onDismissed: (direction) async {
                                await _categoryRepository
                                    .deleteCategory(category.id);
                                _loadCategories();
                                _updateSearch();
                              },
                              child: CategoryCard(
                                category: category,
                                linkCount: _categoryRepository
                                    .getLinkCount(category.id),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        CategoryScreen(category: category),
                                  ),
                                ),
                                onDelete: () => _deleteCategory(category),
                              ),
                            );
                          },
                        ),
                  if (_isRefreshing)
                    Container(
                      color: Colors.black.withValues(alpha: 0.15),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        backgroundColor: AppColors.navy,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }
}
