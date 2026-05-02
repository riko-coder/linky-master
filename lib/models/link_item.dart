import 'package:hive/hive.dart';

part 'link_item.g.dart';

@HiveType(typeId: 1)
class LinkItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String url;

  @HiveField(3)
  final String categoryId;

  @HiveField(4)
  final DateTime createdAt;

  LinkItem({
    required this.id,
    required this.title,
    required this.url,
    required this.categoryId,
    required this.createdAt,
  });

  LinkItem copyWith({
    String? id,
    String? title,
    String? url,
    String? categoryId,
    DateTime? createdAt,
  }) {
    return LinkItem(
      id: id ?? this.id,
      title: title ?? this.title,
      url: url ?? this.url,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'categoryId': categoryId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory LinkItem.fromMap(Map<String, dynamic> map) {
    return LinkItem(
      id: map['id'] as String,
      title: map['title'] as String,
      url: map['url'] as String,
      categoryId: map['categoryId'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  @override
  String toString() => 'LinkItem(id: $id, title: $title, url: $url)';
}
