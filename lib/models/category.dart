import 'package:hive/hive.dart';

part 'category.g.dart';

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

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(id: map['id'] as String, name: map['name'] as String);
  }

  @override
  String toString() => 'Category(id: $id, name: $name)';
}
