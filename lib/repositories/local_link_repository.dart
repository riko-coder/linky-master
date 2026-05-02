import '../models/link_item.dart';
import '../storage/hive_service.dart';
import 'link_repository.dart';

class LocalLinkRepository implements LinkRepository {
  @override
  Future<void> addLink(LinkItem link) async {
    await HiveService.addLink(link);
  }

  @override
  List<LinkItem> getLinksByCategory(String categoryId) {
    return HiveService.getLinksByCategory(categoryId);
  }

  @override
  Future<void> deleteLink(String id) async {
    await HiveService.deleteLink(id);
  }
}
