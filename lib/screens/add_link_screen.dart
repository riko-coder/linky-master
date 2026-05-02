import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/link_item.dart';
import '../repositories/local_category_repository.dart';
import '../repositories/category_repository.dart';
import '../repositories/local_link_repository.dart';
import '../repositories/link_repository.dart';
import '../utils/app_colors.dart';

class AddLinkScreen extends StatefulWidget {
  final String? initialUrl;
  final Category? preselectedCategory;

  const AddLinkScreen({super.key, this.initialUrl, this.preselectedCategory});

  @override
  State<AddLinkScreen> createState() => _AddLinkScreenState();
}

class _AddLinkScreenState extends State<AddLinkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();

  final CategoryRepository _categoryRepository = LocalCategoryRepository();
  final LinkRepository _linkRepository = LocalLinkRepository();

  List<Category> _categories = [];
  Category? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _categories = _categoryRepository.getCategories();
    if (widget.initialUrl != null) {
      _urlController.text = widget.initialUrl!;
    }
    if (widget.preselectedCategory != null) {
      _selectedCategory = widget.preselectedCategory;
    }
  }

  Future<void> _saveLink() async {
    if (_formKey.currentState!.validate()) {
      final title = _titleController.text.trim();
      final url = _urlController.text.trim();

      final link = LinkItem(
        id: DateTime.now().toString(),
        title: title,
        url: url,
        categoryId: _selectedCategory!.id,
        createdAt: DateTime.now(),
      );

      await _linkRepository.addLink(link);

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isPreselected = widget.preselectedCategory != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Link'),
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Enter link title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'https://example.com',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a URL';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            if (!isPreselected)
              DropdownButtonFormField<Category>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
            if (isPreselected) ...[
              Text(
                'Category: ${widget.preselectedCategory!.name}',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.navy,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveLink,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
