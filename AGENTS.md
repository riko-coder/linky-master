# AGENTS.md

**Linky** is a Flutter app for organizing and managing links by category with Android share intent support.

- **Framework**: Flutter 3.x with Dart (SDK: ^3.11.4)
- **State Management**: StatefulWidget with setState
- **Storage**: Hive (NoSQL)
- **Architecture**: Clean Architecture (models, repositories, screens, widgets, utils, storage)

## Build / Lint / Test Commands

```bash
# Install dependencies
flutter pub get

# Run the app (Android)
flutter run

# Build debug/release APK (Android)
flutter build apk --debug
flutter build apk --release

# Analyze code for errors/warnings
flutter analyze

# Run all tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Run tests with coverage
flutter test --coverage

# Generate Hive type adapters after modifying models
dart run build_runner build --delete-conflicting-outputs

# Clean and reinstall
flutter clean && flutter pub get
```

## File Structure

```
lib/
  main.dart
  models/          # Data models (with Hive annotations)
  repositories/    # Abstract interfaces + concrete implementations
  screens/         # Full-page widgets
  storage/         # Hive service and data access
  utils/           # App-wide constants (colors, themes)
  widgets/         # Reusable UI components
```

## Imports

Group imports: 1) Dart core, 2) Flutter, 3) Packages, 4) Relative

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/category.dart';
```

## Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Classes | PascalCase | `CategoryScreen`, `LinkItem` |
| Files | snake_case.dart | `category_card.dart`, `app_colors.dart` |
| Variables/Methods | camelCase | `_categoryRepository`, `_loadCategories` |
| Constants | SCREAMING_SNAKE_CASE | `MAX_ITEMS`, `DEFAULT_COLOR` |
| Private members | Prefix with `_` | `_categories`, `_handleInitialShare` |

## Widgets

- Prefer `const` constructors when possible
- Use trailing commas in lists and parameters
- Prefer `StatelessWidget` unless state management is needed
- Always override `dispose()` in `StatefulWidget`

## State Management Pattern

```dart
class _MyWidgetState extends State<MyWidget> {
  final MyRepository _repository = LocalMyRepository();
  List<Item> _items = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _asyncAction() async {
    await _repository.doSomething();
    if (mounted) {
      setState(() { /* ... */ });
    }
  }
}
```

## Models (Hive)

```dart
@HiveType(typeId: 0)
class Category extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  Category({required this.id, required this.name});

  Category copyWith({String? id, String? name}) {
    return Category(id: id ?? this.id, name: name ?? this.name);
  }
}
```

Include `toMap()`, `fromMap()`, `copyWith()`, and `toString()` in models.

## Repository Pattern

Define abstract interface, implement with `Local` prefix (e.g., `LocalCategoryRepository`).

## Error Handling

- Use `try-catch` for async operations
- Always check `mounted` before `setState()` after async operations
- Use `context.mounted` (Flutter 3.7+) for context access in async callbacks

## Testing

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('description', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Expected'), findsOneWidget);
  });
}
```

## Key Dependencies

| Package | Purpose |
|---------|---------|
| `hive` / `hive_flutter` | Local NoSQL storage |
| `receive_sharing_intent` | Handle shared URLs from other apps |
| `url_launcher` | Open URLs in browser |
| `flutter_lints` | Linting rules |
| `hive_generator` / `build_runner` | Code generation for Hive adapters |
