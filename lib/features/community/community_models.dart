class FeedItem {
  final String id;
  final String uid;
  final String name;
  final String description;
  final String? cone;
  final String? firingType;
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
    required this.name,
    required this.description,
    this.cone,
    this.firingType,
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
        name: j['name'] as String? ?? '',
        description: j['description'] as String? ?? '',
        cone: j['cone'] as String?,
        firingType: j['firingType'] as String?,
        tempScale: j['tempScale'] as String?,
        maxCone: j['maxCone'] as String?,
        imageUrl: j['imageUrl'] as String?,
        likeCount: (j['likeCount'] as num?)?.toInt() ?? 0,
        dateModified: j['dateModified'] as String? ?? '',
        dateCreated: j['dateCreated'] as String? ?? '',
        itemType: j['itemType'] as String? ?? 'recipe',
      );
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
