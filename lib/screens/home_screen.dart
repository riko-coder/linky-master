import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/category.dart';
import '../models/link_item.dart';
import '../storage/hive_service.dart';
import '../utils/app_colors.dart';
import '../utils/search_utils.dart';
import '../widgets/category_card.dart';
import '../repositories/local_category_repository.dart';
import '../repositories/category_repository.dart';
import '../repositories/local_link_repository.dart';
import '../repositories/link_repository.dart';
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
  final LinkRepository _linkRepository = LocalLinkRepository();
  List<Category> _categories = [];
  List<Category> _filteredCategories = [];
  List<LinkItem> _filteredLinks = [];
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
        _filteredLinks = [];
      } else {
        // Search categories by name
        _filteredCategories = SearchUtils.searchAndSort(
          query,
          _categories,
          (category) => category.name,
        );
        // Search links by title
        final allLinks = _linkRepository.getAllLinks();
        _filteredLinks = SearchUtils.searchAndSort(
          query,
          allLinks,
          (link) => link.title,
        );
      }
    });
  }

  void _loadCategories() {
    setState(() {
      _categories = _categoryRepository.getCategories();
      _filteredCategories = _categories;
      _filteredLinks = [];
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

  Future<void> _openLink(BuildContext context, String url) async {
    // Ensure URL has a scheme - add https:// if missing
    String urlToOpen = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      urlToOpen = 'https://$url';
    }

    final uri = Uri.parse(urlToOpen);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $e')),
        );
      }
    }
  }

  void _deleteLink(LinkItem link) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Link'),
        content: Text('Are you sure you want to delete "${link.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await _linkRepository.deleteLink(link.id);
              _loadCategories();
              _updateSearch();
              if (mounted) navigator.pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Find the category name for a given link's categoryId
  String _getCategoryName(String categoryId) {
    try {
      return _categories.firstWhere((c) => c.id == categoryId).name;
    } catch (_) {
      return 'Unknown';
    }
  }

  /// Format a DateTime to a readable string like "Oct 24, 2023 at 14:30"
  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final month = months[date.month - 1];
    final day = date.day;
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$month $day, $year at $hour:$minute';
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDarkMode ? AppColors.darkText : AppColors.navy;
    final urlColor = isDarkMode ? AppColors.darkTeal : AppColors.teal;

    // Determine if we are in search mode with link results
    final bool showLinkResults =
        _searchQuery.isNotEmpty && _filteredLinks.isNotEmpty;
    final bool hasNoResults = _searchQuery.isNotEmpty &&
        _filteredCategories.isEmpty &&
        _filteredLinks.isEmpty;

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
                hintText: 'Search categories & links...',
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
          // Results List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: Stack(
                children: [
                  hasNoResults
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: const Center(
                            child: Text(
                              'No results found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      : (_filteredCategories.isEmpty && !showLinkResults)
                          ? SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: const Center(
                                child: Text(
                                  'No categories yet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            )
                          : ListView(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              children: [
                                // Category results
                                ..._filteredCategories.map((category) {
                                  return Dismissible(
                                    key: Key(category.id),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 16),
                                      color: Colors.red,
                                      child: const Icon(Icons.delete,
                                          color: Colors.white),
                                    ),
                                    confirmDismiss: (direction) async {
                                      return await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title:
                                              const Text('Delete Category'),
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
                                                style: TextStyle(
                                                    color: Colors.red),
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
                                          builder: (_) => CategoryScreen(
                                              category: category),
                                        ),
                                      ),
                                      onDelete: () =>
                                          _deleteCategory(category),
                                    ),
                                  );
                                }),
                                // Link results (only when searching)
                                if (showLinkResults) ...[
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 8, bottom: 8),
                                    child: Text(
                                      'Links',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isDarkMode
                                            ? AppColors.darkSecondaryText
                                            : AppColors.teal,
                                      ),
                                    ),
                                  ),
                                  ..._filteredLinks.map((link) {
                                    final categoryName =
                                        _getCategoryName(link.categoryId);
                                    return Card(
                                      margin:
                                          const EdgeInsets.only(bottom: 12),
                                      child: InkWell(
                                        onTap: () =>
                                            _openLink(context, link.url),
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start,
                                                  children: [
                                                    Text(
                                                      link.title,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                        color: titleColor,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      _formatDate(
                                                          link.createdAt),
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: titleColor
                                                            .withValues(
                                                                alpha: 0.5),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      link.url,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: urlColor,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      categoryName,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: isDarkMode
                                                            ? AppColors
                                                                .darkSecondaryText
                                                            : AppColors.teal
                                                                .withValues(
                                                                    alpha:
                                                                        0.7),
                                                        fontStyle:
                                                            FontStyle.italic,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete,
                                                    color: Colors.red),
                                                onPressed: () =>
                                                    _deleteLink(link),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ],
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
