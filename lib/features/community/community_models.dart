class FeedItem {
  final String id;
  final String uid;
  final String displayName;
  final String name;
  final String description;
  final String? cone;
  final String? firingType;
  final List<String> color;
  final String? finish;
  final String? surface;
  final String? transparency;
  final String? tempScale;
  final String? maxCone;
  final String? imageUrl;
  final int likeCount;
  final String dateModified;
  final String dateCreated;
  final String itemType; // 'recipe' | 'schedule'

  const FeedItem({
    required this.id,
    required this.uid,
    this.displayName = '',
    required this.name,
    required this.description,
    this.cone,
    this.firingType,
    this.color = const [],
    this.finish,
    this.surface,
    this.transparency,
    this.tempScale,
    this.maxCone,
    this.imageUrl,
    required this.likeCount,
    required this.dateModified,
    required this.dateCreated,
    required this.itemType,
  });

  bool get isRecipe => itemType == 'recipe';

  factory FeedItem.fromJson(Map<String, dynamic> j) => FeedItem(
        id: j['id'] as String? ?? '',
        uid: j['uid'] as String? ?? '',
        displayName: j['displayName'] as String? ?? '',
        name: j['name'] as String? ?? '',
        description: j['description'] as String? ?? '',
        cone: j['cone'] as String?,
        firingType: j['firingType'] as String?,
        color: (j['color'] as List<dynamic>? ?? []).cast<String>(),
        finish: j['finish'] as String?,
        surface: j['surface'] as String?,
        transparency: j['transparency'] as String?,
        tempScale: j['tempScale'] as String?,
        maxCone: j['maxCone'] as String?,
        imageUrl: j['imageUrl'] as String?,
        likeCount: (j['likeCount'] as num?)?.toInt() ?? 0,
        dateModified: j['dateModified'] as String? ?? '',
        dateCreated: j['dateCreated'] as String? ?? '',
        itemType: j['itemType'] as String? ?? 'recipe',
      );
}

/// A potter's public profile (GET /users/{uid}).
class PublicProfile {
  final String uid;
  final String displayName;
  final String bio;
  final String? photoUrl;
  final int followerCount;
  final int followingCount;
  final int recipeCount;
  final String createdAt;

  const PublicProfile({
    required this.uid,
    required this.displayName,
    this.bio = '',
    this.photoUrl,
    this.followerCount = 0,
    this.followingCount = 0,
    this.recipeCount = 0,
    this.createdAt = '',
  });

  factory PublicProfile.fromJson(Map<String, dynamic> j) => PublicProfile(
        uid: j['uid'] as String? ?? '',
        displayName: j['displayName'] as String? ?? '',
        bio: j['bio'] as String? ?? '',
        photoUrl: j['photoUrl'] as String?,
        followerCount: (j['followerCount'] as num?)?.toInt() ?? 0,
        followingCount: (j['followingCount'] as num?)?.toInt() ?? 0,
        recipeCount: (j['recipeCount'] as num?)?.toInt() ?? 0,
        createdAt: j['createdAt'] as String? ?? '',
      );
}

/// One page of the global feed plus the cursor for the next page (null when
/// there are no more items).
class FeedPage {
  final List<FeedItem> items;
  final String? nextCursor;

  const FeedPage({required this.items, this.nextCursor});

  bool get hasMore => nextCursor != null && nextCursor!.isNotEmpty;
}

class FeedComment {
  final String commentId;
  final String uid;
  final String displayName;
  final String photoUrl;
  final String body;
  final String? parentCommentId;
  final String dateCreated;

  const FeedComment({
    required this.commentId,
    required this.uid,
    required this.displayName,
    required this.photoUrl,
    required this.body,
    this.parentCommentId,
    required this.dateCreated,
  });

  factory FeedComment.fromJson(Map<String, dynamic> j) => FeedComment(
        commentId: j['commentId'] as String? ?? '',
        uid: j['uid'] as String? ?? '',
        displayName: j['displayName'] as String? ?? 'Anonymous',
        photoUrl: j['photoUrl'] as String? ?? '',
        body: j['body'] as String? ?? '',
        parentCommentId: j['parentCommentId'] as String?,
        dateCreated: j['dateCreated'] as String? ?? '',
      );
}
