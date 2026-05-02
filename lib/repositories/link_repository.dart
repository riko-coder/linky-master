import '../models/link_item.dart';

abstract class LinkRepository {
  Future<void> addLink(LinkItem link);
  List<LinkItem> getLinksByCategory(String categoryId);
  Future<void> deleteLink(String id);
}
