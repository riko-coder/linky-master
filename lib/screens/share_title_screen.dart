import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/category.dart';
import '../models/link_item.dart';
import '../repositories/local_link_repository.dart';
import '../repositories/link_repository.dart';
import '../utils/app_colors.dart';

class ShareTitleScreen extends StatefulWidget {
  final String sharedUrl;
  final Category category;

  const ShareTitleScreen({
    super.key,
    required this.sharedUrl,
    required this.category,
  });

  @override
  State<ShareTitleScreen> createState() => _ShareTitleScreenState();
}

class _ShareTitleScreenState extends State<ShareTitleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final LinkRepository _linkRepository = LocalLinkRepository();

  static const _platform = MethodChannel('com.example.linky_2/close');

  Future<void> _openUrl() async {
    final uri = Uri.parse(widget.sharedUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _closeApp() async {
    try {
      await _platform.invokeMethod('closeApp');
    } catch (e) {
      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    }
  }

  Future<void> _saveLink() async {
    if (_formKey.currentState!.validate()) {
      final title = _titleController.text.trim();
      final url = widget.sharedUrl;

      final link = LinkItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        url: url,
        categoryId: widget.category.id,
        createdAt: DateTime.now(),
      );

      await _linkRepository.addLink(link);

      if (mounted) {
        _closeApp();
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Link'),
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _closeApp,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.beige,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.folder,
                    color: AppColors.teal,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.category.name,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.navy,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final isDarkMode =
                    Theme.of(context).brightness == Brightness.dark;
                final backgroundColor = isDarkMode
                    ? AppColors.darkCard.withValues(alpha: 0.5)
                    : AppColors.skyBlue.withValues(alpha: 0.3);
                final borderColor = isDarkMode
                    ? AppColors.darkTeal.withValues(alpha: 0.4)
                    : AppColors.teal.withValues(alpha: 0.3);
                final textColor =
                    isDarkMode ? AppColors.darkText : AppColors.navy;
                final iconColor =
                    isDarkMode ? AppColors.darkTeal : AppColors.teal;

                return InkWell(
                  onTap: _openUrl,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.link,
                          color: iconColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.sharedUrl,
                            style: TextStyle(
                              fontSize: 13,
                              color: textColor,
                              decoration: TextDecoration.underline,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.open_in_new,
                          color: iconColor,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Enter a title for this link',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _closeApp,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.navy),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.navy),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveLink,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
