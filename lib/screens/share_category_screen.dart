import 'package:flutter/material.dart';
import '../models/category.dart';
import '../repositories/local_category_repository.dart';
import '../repositories/category_repository.dart';
import '../utils/app_colors.dart';
import 'share_title_screen.dart';

class ShareCategoryScreen extends StatefulWidget {
  final String sharedUrl;

  const ShareCategoryScreen({super.key, required this.sharedUrl});

  @override
  State<ShareCategoryScreen> createState() => _ShareCategoryScreenState();
}

class _ShareCategoryScreenState extends State<ShareCategoryScreen> {
  final CategoryRepository _categoryRepository = LocalCategoryRepository();
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() {
    setState(() {
      _categories = _categoryRepository.getCategories();
    });
  }

  void _navigateToTitleScreen(Category category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShareTitleScreen(
          sharedUrl: widget.sharedUrl,
          category: category,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share to Linky'),
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _categories.isEmpty
          ? const Center(
              child: Text(
                'No categories yet.\nCreate categories in the app first.',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _categories.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final category = _categories[index];
                return _CategoryListTile(
                  category: category,
                  onTap: () => _navigateToTitleScreen(category),
                );
              },
            ),
    );
  }
}

class _CategoryListTile extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;

  const _CategoryListTile({
    required this.category,
    required this.onTap,
  });

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0][0].toUpperCase();
    }
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  Color _getAvatarColor(String name) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.red,
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getAvatarColor(category.name),
        foregroundColor: Colors.white,
        child: Text(
          _getInitials(category.name),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(
        category.name,
        style: const TextStyle(fontSize: 16),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.teal,
      ),
      onTap: onTap,
    );
  }
}
