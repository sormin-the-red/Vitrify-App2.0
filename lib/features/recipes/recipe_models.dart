class RecipeIngredient {
  final String name;
  final double percentage;
  final bool isAddition;

  const RecipeIngredient({
    required this.name,
    required this.percentage,
    this.isAddition = false,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> j) => RecipeIngredient(
        name: (j['name'] ?? j['Name'] ?? '') as String,
        percentage:
            ((j['percentage'] ?? j['Percentage'] ?? 0) as num).toDouble(),
        isAddition: j['isAddition'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'percentage': percentage,
        if (isAddition) 'isAddition': true,
      };
}

class RecipeRevision {
  final int revisionNum;
  final List<RecipeIngredient> materials;
  final List<String> imageUrls;
  final String notes;
  final String status;
  final String dateCreated;

  const RecipeRevision({
    required this.revisionNum,
    required this.materials,
    required this.imageUrls,
    required this.notes,
    required this.status,
    required this.dateCreated,
  });

  factory RecipeRevision.fromJson(Map<String, dynamic> j) => RecipeRevision(
        revisionNum: (j['revisionNum'] as num?)?.toInt() ?? 1,
        materials: (j['materials'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(RecipeIngredient.fromJson)
            .toList(),
        imageUrls: (j['imageUrls'] as List<dynamic>? ?? []).cast<String>(),
        notes: j['notes'] as String? ?? '',
        status: j['status'] as String? ?? 'New',
        dateCreated: j['dateCreated'] as String? ?? '',
      );
}

class RecipeSummary {
  final String id;
  final String uid;
  final String name;
  final String cone;
  final String firingType;
  final List<String> color;
  final String finish;
  final String surface;
  final String transparency;
  final bool isPublic;
  final int likeCount;
  final int revisionCount;
  final String imageUrl;
  final String status;
  final String dateCreated;
  final String dateModified;

  const RecipeSummary({
    required this.id,
    required this.uid,
    required this.name,
    required this.cone,
    required this.firingType,
    this.color = const [],
    this.finish = '',
    this.surface = '',
    this.transparency = '',
    required this.isPublic,
    required this.likeCount,
    required this.revisionCount,
    required this.imageUrl,
    required this.status,
    required this.dateCreated,
    required this.dateModified,
  });

  factory RecipeSummary.fromJson(Map<String, dynamic> j) => RecipeSummary(
        id: j['id'] as String? ?? '',
        uid: j['uid'] as String? ?? '',
        name: j['name'] as String? ?? 'Untitled Recipe',
        cone: j['cone'] as String? ?? '',
        firingType: j['firingType'] as String? ?? '',
        color: (j['color'] as List<dynamic>? ?? []).cast<String>(),
        finish: j['finish'] as String? ?? '',
        surface: j['surface'] as String? ?? '',
        transparency: j['transparency'] as String? ?? '',
        isPublic: j['public'] as bool? ?? false,
        likeCount: (j['likeCount'] as num?)?.toInt() ?? 0,
        revisionCount: (j['revisionCount'] as num?)?.toInt() ?? 1,
        imageUrl: j['imageUrl'] as String? ?? '',
        status: j['status'] as String? ?? 'New',
        dateCreated: j['dateCreated'] as String? ?? '',
        dateModified: j['dateModified'] as String? ?? '',
      );
}

class RecipeDetail extends RecipeSummary {
  final String description;
  final String notes;
  final RecipeRevision? revision;
  final List<RecipeRevision> revisions;
  final String? duplicateOriginId;
  final String? duplicateOriginName;

  const RecipeDetail({
    required super.id,
    required super.uid,
    required super.name,
    required super.cone,
    required super.firingType,
    super.color,
    super.finish,
    super.surface,
    super.transparency,
    required super.isPublic,
    required super.likeCount,
    required super.revisionCount,
    required super.imageUrl,
    required super.status,
    required super.dateCreated,
    required super.dateModified,
    required this.description,
    required this.notes,
    this.revision,
    this.revisions = const [],
    this.duplicateOriginId,
    this.duplicateOriginName,
  });

  RecipeDetail copyWith({RecipeRevision? revision}) => RecipeDetail(
        id: id, uid: uid, name: name, cone: cone, firingType: firingType,
        color: color, finish: finish, surface: surface, transparency: transparency,
        isPublic: isPublic, likeCount: likeCount, revisionCount: revisionCount,
        imageUrl: imageUrl, status: status,
        dateCreated: dateCreated, dateModified: dateModified,
        description: description, notes: notes,
        revision: revision ?? this.revision,
        revisions: revisions,
        duplicateOriginId: duplicateOriginId,
        duplicateOriginName: duplicateOriginName,
      );

  factory RecipeDetail.fromJson(Map<String, dynamic> j) => RecipeDetail(
        id: j['id'] as String? ?? '',
        uid: j['uid'] as String? ?? '',
        name: j['name'] as String? ?? 'Untitled Recipe',
        cone: j['cone'] as String? ?? '',
        firingType: j['firingType'] as String? ?? '',
        color: (j['color'] as List<dynamic>? ?? []).cast<String>(),
        finish: j['finish'] as String? ?? '',
        surface: j['surface'] as String? ?? '',
        transparency: j['transparency'] as String? ?? '',
        isPublic: j['public'] as bool? ?? false,
        likeCount: (j['likeCount'] as num?)?.toInt() ?? 0,
        revisionCount: (j['revisionCount'] as num?)?.toInt() ?? 1,
        imageUrl: j['imageUrl'] as String? ?? '',
        status: j['status'] as String? ?? 'New',
        dateCreated: j['dateCreated'] as String? ?? '',
        dateModified: j['dateModified'] as String? ?? '',
        description: j['description'] as String? ?? '',
        notes: j['notes'] as String? ?? '',
        revision: j['revision'] != null
            ? RecipeRevision.fromJson(j['revision'] as Map<String, dynamic>)
            : null,
        revisions: (j['revisions'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(RecipeRevision.fromJson)
            .toList(),
        duplicateOriginId: j['duplicateOriginId'] as String?,
        duplicateOriginName: j['duplicateOriginName'] as String?,
      );
}
