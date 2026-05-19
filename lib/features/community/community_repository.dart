import 'dart:async';
import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/network/api_client.dart';
import 'community_models.dart';

part 'community_repository.g.dart';

class CommunityRepository {
  CommunityRepository(this._api);
  final ApiClient _api;

  Future<List<FeedItem>> getGlobalFeed({
    String filter = 'new',
    String type = 'all',
    int limit = 30,
  }) async {
    final res =
        await _api.get('/feed?filter=$filter&type=$type&limit=$limit');
    if (res.statusCode != 200) throw Exception('Failed to load feed');
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final items = body['items'] as List<dynamic>? ?? [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(FeedItem.fromJson)
        .toList();
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
}

@Riverpod(keepAlive: true)
CommunityRepository communityRepository(CommunityRepositoryRef ref) =>
    CommunityRepository(ref.watch(apiClientProvider));

/// [filterKey] is formatted as "filter:type" (e.g. "new:all", "popular:all", "new:schedules").
@riverpod
Future<List<FeedItem>> globalFeed(GlobalFeedRef ref, String filterKey) {
  final parts = filterKey.split(':');
  final filter = parts[0];
  final type = parts.length > 1 ? parts[1] : 'all';
  return ref.watch(communityRepositoryProvider).getGlobalFeed(filter: filter, type: type);
}

@riverpod
Future<List<FeedItem>> followingFeed(FollowingFeedRef ref) =>
    ref.watch(communityRepositoryProvider).getFollowingFeed();
