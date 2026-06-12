import 'dart:async';
import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/network/api_client.dart';
import 'community_models.dart';

part 'community_repository.g.dart';

class CommunityRepository {
  CommunityRepository(this._api);
  final ApiClient _api;

  Future<FeedPage> getGlobalFeed({
    String filter = 'new',
    String type = 'all',
    int limit = 30,
    String? cursor,
  }) async {
    var path = '/feed?filter=$filter&type=$type&limit=$limit';
    if (cursor != null && cursor.isNotEmpty) {
      path += '&cursor=${Uri.encodeQueryComponent(cursor)}';
    }
    final res = await _api.get(path);
    if (res.statusCode != 200) throw Exception('Failed to load feed');
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final items = body['items'] as List<dynamic>? ?? [];
    return FeedPage(
      items: items
          .whereType<Map<String, dynamic>>()
          .map(FeedItem.fromJson)
          .toList(),
      nextCursor: body['nextCursor'] as String?,
    );
  }

  Future<List<FeedItem>> getFollowingFeed({int limit = 30}) async {
    final res = await _api.get('/feed/following?limit=$limit');
    if (res.statusCode != 200) throw Exception('Failed to load following feed');
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final items = body['items'] as List<dynamic>? ?? [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(FeedItem.fromJson)
        .toList();
  }

  Future<void> heart(FeedItem item) async {
    final path = item.isRecipe
        ? '/recipes/${item.id}/heart'
        : '/schedules/${item.id}/heart';
    await _api.post(path);
  }

  Future<void> unheart(FeedItem item) async {
    final path = item.isRecipe
        ? '/recipes/${item.id}/heart'
        : '/schedules/${item.id}/heart';
    await _api.delete(path);
  }

  Future<List<FeedComment>> getComments(FeedItem item) async {
    final path = item.isRecipe
        ? '/recipes/${item.id}/comments'
        : '/schedules/${item.id}/comments';
    final res = await _api.get(path);
    if (res.statusCode != 200) throw Exception('Failed to load comments');
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .whereType<Map<String, dynamic>>()
        .map(FeedComment.fromJson)
        .toList();
  }

  Future<void> addComment(FeedItem item, String body, {String? parentId}) async {
    final path = item.isRecipe
        ? '/recipes/${item.id}/comments'
        : '/schedules/${item.id}/comments';
    await _api.post(path, body: {
      'body': body,
      'parentCommentId': ?parentId,
    });
  }

  Future<PublicProfile> getUserProfile(String uid) async {
    final res = await _api.get('/users/$uid');
    if (res.statusCode != 200) throw Exception('Failed to load profile');
    return PublicProfile.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<FeedItem>> getUserRecipes(String uid) async {
    final res = await _api.get('/users/$uid/recipes');
    if (res.statusCode != 200) throw Exception('Failed to load recipes');
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .whereType<Map<String, dynamic>>()
        .map(FeedItem.fromJson)
        .toList();
  }

  Future<void> follow(String uid) async {
    final res = await _api.post('/users/$uid/follow');
    if (res.statusCode != 200) throw Exception('Failed to follow');
  }

  Future<void> unfollow(String uid) async {
    final res = await _api.delete('/users/$uid/follow');
    if (res.statusCode != 200) throw Exception('Failed to unfollow');
  }

  /// Whether the signed-in user follows [uid] — derived from their own
  /// following list (no dedicated endpoint).
  Future<bool> isFollowing(String myUid, String uid) async {
    final res = await _api.get('/users/$myUid/following');
    if (res.statusCode != 200) return false;
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .whereType<Map<String, dynamic>>()
        .any((f) => f['uid'] == uid);
  }
}

@Riverpod(keepAlive: true)
CommunityRepository communityRepository(CommunityRepositoryRef ref) =>
    CommunityRepository(ref.watch(apiClientProvider));

/// [filterKey] is formatted as "filter:type" (e.g. "new:all", "popular:all", "new:schedules").
/// Returns the first page; subsequent pages are fetched imperatively with the
/// page's [FeedPage.nextCursor] (see `_GlobalFeedTab`).
@riverpod
Future<FeedPage> globalFeed(GlobalFeedRef ref, String filterKey) {
  final parts = filterKey.split(':');
  final filter = parts[0];
  final type = parts.length > 1 ? parts[1] : 'all';
  return ref.watch(communityRepositoryProvider).getGlobalFeed(filter: filter, type: type);
}

@riverpod
Future<List<FeedItem>> followingFeed(FollowingFeedRef ref) =>
    ref.watch(communityRepositoryProvider).getFollowingFeed();

@riverpod
Future<PublicProfile> userProfile(UserProfileRef ref, String uid) =>
    ref.watch(communityRepositoryProvider).getUserProfile(uid);

@riverpod
Future<List<FeedItem>> userRecipes(UserRecipesRef ref, String uid) =>
    ref.watch(communityRepositoryProvider).getUserRecipes(uid);
