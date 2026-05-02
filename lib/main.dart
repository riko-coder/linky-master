import 'dart:async';
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'utils/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/share_category_screen.dart';
import 'storage/hive_service.dart';
import 'storage/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  await ThemeService.init();
  runApp(const LinkyApp());
}

class LinkyApp extends StatefulWidget {
  const LinkyApp({super.key});

  @override
  State<LinkyApp> createState() => _LinkyAppState();
}

class _LinkyAppState extends State<LinkyApp> {
  StreamSubscription? _shareSubscription;
  String? _shareUrl;
  late StreamSubscription _themeSubscription;

  @override
  void initState() {
    super.initState();
    _handleInitialShare();
    _handleShareStream();
    // Listen to theme changes
    _themeSubscription = ThemeService.themeBox.watch().listen((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _shareSubscription?.cancel();
    _themeSubscription.cancel();
    super.dispose();
  }

  void _handleInitialShare() async {
    final initialMedia = await ReceiveSharingIntent.instance.getInitialMedia();
    if (initialMedia.isNotEmpty) {
      final media = initialMedia.firstWhere(
        (m) => m.type == SharedMediaType.text || m.type == SharedMediaType.url,
        orElse: () => initialMedia.first,
      );
      ReceiveSharingIntent.instance.reset();
      setState(() {
        _shareUrl = media.path;
      });
    }
  }

  void _handleShareStream() {
    _shareSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((
      mediaList,
    ) {
      if (mediaList.isNotEmpty) {
        final media = mediaList.firstWhere(
          (m) => m.type == SharedMediaType.text || m.type == SharedMediaType.url,
          orElse: () => mediaList.first,
        );
        ReceiveSharingIntent.instance.reset();
        setState(() {
          _shareUrl = media.path;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Linky',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: _shareUrl != null
          ? ShareCategoryScreen(sharedUrl: _shareUrl!)
          : const HomeScreen(),
    );
  }
}
