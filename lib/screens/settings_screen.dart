import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import '../storage/hive_service.dart';
import '../storage/theme_service.dart';
import '../utils/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isExporting = false;
  bool _isImporting = false;

  Future<void> _exportData() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final jsonData = HiveService.exportDataAsJson();

      if (mounted) {
        setState(() {
          _isExporting = false;
        });

        // Show dialog with JSON data
        return showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Export Data'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your exported data (JSON):',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: SelectableText(
                        jsonData,
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: jsonData));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Data copied to clipboard!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy to Clipboard'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importDataDialog() async {
    final controller = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste your exported JSON data:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              minLines: 8,
              maxLines: 12,
              decoration: InputDecoration(
                hintText: 'Paste JSON here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              title: const Text('Merge with existing data'),
              subtitle:
                  const Text('If unchecked, existing data will be replaced'),
              value: true,
              onChanged: null,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _performImport(controller.text, merge: true);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Import & Merge'),
          ),
        ],
      ),
    );
  }

  Future<void> _performImport(String jsonData, {bool merge = true}) async {
    if (jsonData.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please paste valid JSON data'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isImporting = true;
    });

    try {
      await HiveService.importDataFromJson(jsonData, merge: merge);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              merge
                  ? 'Data imported and merged successfully!'
                  : 'Data imported successfully!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _toggleDarkMode(bool value) async {
    await ThemeService.setDarkMode(value);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDarkMode ? AppColors.darkText : AppColors.navy;
    final secondaryTextColor =
        isDarkMode ? AppColors.darkSecondaryText : Colors.grey;
    final headingColor = isDarkMode ? AppColors.darkText : AppColors.navy;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Mode Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: headingColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            ThemeService.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                            color: isDarkMode ? AppColors.darkTeal : AppColors.teal,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dark Mode',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: primaryTextColor,
                                ),
                              ),
                              Text(
                                ThemeService.isDarkMode
                                    ? 'Enabled'
                                    : 'Disabled',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Switch(
                        value: ThemeService.isDarkMode,
                        onChanged: _toggleDarkMode,
                        activeColor: isDarkMode
                            ? AppColors.darkTeal
                            : AppColors.teal,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // About Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About Linky',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: headingColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Version',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: primaryTextColor,
                    ),
                  ),
                  Text(
                    '1.0.0',
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Description',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: primaryTextColor,
                    ),
                  ),
                  Text(
                    'Linky is a simple and elegant link management app. '
                    'Organize your bookmarks by categories and manage your '
                    'links efficiently with a beautiful, intuitive interface.',
                   
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Features',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• Organize links by categories',
                          style: TextStyle(
                              color: secondaryTextColor, fontSize: 13)),
                      Text('• Quick search and filtering',
                          style: TextStyle(
                              color: secondaryTextColor, fontSize: 13)),
                      Text('• Android share intent support',
                          style: TextStyle(
                              color: secondaryTextColor, fontSize: 13)),
                      Text('• Data import/export capability',
                          style: TextStyle(
                              color: secondaryTextColor, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Credits Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDarkMode
                            ? AppColors.darkTeal
                            : AppColors.teal,
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/avatar.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: isDarkMode
                                ? AppColors.darkCard
                                : Colors.grey[200],
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color: isDarkMode
                                  ? AppColors.darkTeal
                                  : AppColors.teal,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Made with Flutter',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: headingColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'by Anirudh',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: primaryTextColor,
                    ),
                  ),
                  Text(
                    '@douicoder',
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          isDarkMode ? AppColors.darkTeal : AppColors.teal,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Data Management Section
          Text(
            'Data Management',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: headingColor,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _isExporting ? null : _exportData,
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.white),
                    ),
                  )
                : const Icon(Icons.download),
            label: Text(_isExporting ? 'Exporting...' : 'Download Data'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode ? AppColors.darkTeal : AppColors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _isImporting ? null : _importDataDialog,
            icon: _isImporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.white),
                    ),
                  )
                : const Icon(Icons.upload),
            label: Text(_isImporting ? 'Importing...' : 'Upload Data'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode ? AppColors.darkTeal : AppColors.navy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 20),
          // Data Management Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? AppColors.darkSurface.withOpacity(0.5)
                  : Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDarkMode
                    ? AppColors.darkTeal.withOpacity(0.3)
                    : Colors.blue.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data Management Info',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDarkMode ? AppColors.darkTeal : AppColors.navy,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Download: Saves your data as a JSON file to your device documents folder\n'
                  '• Upload: Paste previously exported JSON data to restore or merge with your current data\n'
                  '• Merge: When importing, new data is merged with existing data without overwriting existing items',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.6,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
