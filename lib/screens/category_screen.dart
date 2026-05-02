import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/category.dart';
import '../models/link_item.dart';
import '../storage/hive_service.dart';
import '../utils/app_colors.dart';
import '../utils/search_utils.dart';
import '../repositories/local_link_repository.dart';
import '../repositories/link_repository.dart';
import 'add_link_screen.dart';

class CategoryScreen extends StatefulWidget {
  final Category category;

  const CategoryScreen({super.key, required this.category});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> with WidgetsBindingObserver {
  final LinkRepository _linkRepository = LocalLinkRepository();
  final TextEditingController _searchController = TextEditingController();
  List<LinkItem> _links = [];
  List<LinkItem> _filteredLinks = [];
  String _searchQuery = '';
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadLinks();
    _searchController.addListener(_updateSearch);
  }

  void _updateSearch() {
    final query = _searchController.text;
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredLinks = _links;
      } else {
        _filteredLinks = SearchUtils.searchAndSort(
          query,
          _links,
          (link) => link.title,
        );
      }
    });
  }

  void _loadLinks() {
    setState(() {
      _links = _linkRepository.getLinksByCategory(widget.category.id);
      _filteredLinks = _links;
    });
  }

  Future<void> _onRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    // Refresh Hive boxes from disk first
    await HiveService.refresh();
    _loadLinks();
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  Future<void> _openLink(BuildContext context, String url) async {
    // Ensure URL has a scheme - add https:// if missing
    String urlToOpen = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      urlToOpen = 'https://$url';
    }
    
    final uri = Uri.parse(urlToOpen);
    try {
      // Try external browser first
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to in-app browser if external fails
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
              _loadLinks();
              _updateSearch();
              if (mounted) navigator.pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _navigateToAddLink() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddLinkScreen(preselectedCategory: widget.category),
      ),
    ).then((_) {
      _loadLinks();
      _updateSearch();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came back to foreground - refresh Hive and reload data
      HiveService.refresh().then((_) {
        if (mounted) {
          _loadLinks();
        }
      });
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
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.category.name)),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search links...',
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
          // Links List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: Stack(
                children: [
                  _filteredLinks.isEmpty
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Center(
                            child: Text(
                              _searchQuery.isEmpty
                                  ? 'No links yet'
                                  : 'No links found',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredLinks.length,
                          itemBuilder: (context, index) {
                            final link = _filteredLinks[index];
                            final isDarkMode =
                                Theme.of(context).brightness == Brightness.dark;
                            final titleColor =
                                isDarkMode ? AppColors.darkText : AppColors.navy;
                            final urlColor = isDarkMode
                                ? AppColors.darkTeal
                                : AppColors.teal;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: () => _openLink(context, link.url),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              link.title,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: titleColor,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _formatDate(link.createdAt),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: titleColor.withValues(alpha: 0.5),
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
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () => _deleteLink(link),
                                      ),
                                    ],
                                  ),
                                ),
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
        onPressed: _navigateToAddLink,
        backgroundColor: AppColors.navy,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }
}
