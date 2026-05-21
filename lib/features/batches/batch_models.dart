class GlazeLayer {
  final int layerOrder;
  final String? recipeId;
  final int? revisionNum;
  final String? recipeName;
  final String? applicationMethod;
  final int? coatCount;
  final String? thickness;

  const GlazeLayer({
    required this.layerOrder,
    this.recipeId,
    this.revisionNum,
    this.recipeName,
    this.applicationMethod,
    this.coatCount,
    this.thickness,
  });

  factory GlazeLayer.fromJson(Map<String, dynamic> j) => GlazeLayer(
        layerOrder: (j['layerOrder'] as num?)?.toInt() ?? 0,
        recipeId: j['recipeId'] as String?,
        revisionNum: (j['revisionNum'] as num?)?.toInt(),
        recipeName: j['recipeName'] as String?,
        applicationMethod: j['applicationMethod'] as String?,
        coatCount: (j['coatCount'] as num?)?.toInt(),
        thickness: j['thickness'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'layerOrder': layerOrder,
        if (recipeId != null) 'recipeId': recipeId,
        if (revisionNum != null) 'revisionNum': revisionNum,
        if (recipeName != null) 'recipeName': recipeName,
        if (applicationMethod != null) 'applicationMethod': applicationMethod,
        if (coatCount != null) 'coatCount': coatCount,
        if (thickness != null) 'thickness': thickness,
      };

  GlazeLayer copyWith({
    int? layerOrder,
    Object? recipeId = _sentinel,
    Object? revisionNum = _sentinel,
    Object? recipeName = _sentinel,
    Object? applicationMethod = _sentinel,
    Object? coatCount = _sentinel,
    Object? thickness = _sentinel,
  }) =>
      GlazeLayer(
        layerOrder: layerOrder ?? this.layerOrder,
        recipeId: recipeId == _sentinel ? this.recipeId : recipeId as String?,
        revisionNum: revisionNum == _sentinel ? this.revisionNum : revisionNum as int?,
        recipeName: recipeName == _sentinel ? this.recipeName : recipeName as String?,
        applicationMethod: applicationMethod == _sentinel ? this.applicationMethod : applicationMethod as String?,
        coatCount: coatCount == _sentinel ? this.coatCount : coatCount as int?,
        thickness: thickness == _sentinel ? this.thickness : thickness as String?,
      );
}

class _Sentinel {
  const _Sentinel();
}

const _sentinel = _Sentinel();

class TestTile {
  final int tileNum;
  final String? tileName;
  final List<GlazeLayer> glazeLayers;
  final String? notes;
  final String? outcome;
  final String? atmosphere;
  final String? temperature;
  final List<String> photoUrls;
  final String? firingScheduleId;

  const TestTile({
    required this.tileNum,
    this.tileName,
    required this.glazeLayers,
    this.notes,
    this.outcome,
    this.atmosphere,
    this.temperature,
    this.photoUrls = const [],
    this.firingScheduleId,
  });

  factory TestTile.fromJson(Map<String, dynamic> j) => TestTile(
        tileNum: (j['tileNum'] as num?)?.toInt() ?? 0,
        tileName: _ne(j['tileName'] as String?),
        glazeLayers: (j['glazeLayers'] as List<dynamic>? ?? [])
            .map((e) => GlazeLayer.fromJson(e as Map<String, dynamic>))
            .toList(),
        notes: _ne(j['notes'] as String?),
        outcome: _ne(j['outcome'] as String?),
        atmosphere: _ne(j['atmosphere'] as String?),
        temperature: _ne(j['temperature'] as String?),
        photoUrls: (j['photoUrls'] as List<dynamic>? ?? []).cast<String>(),
        firingScheduleId: _ne(j['firingScheduleId'] as String?),
      );

  // Backend stores "" for unset optional fields; treat as null on the client.
  static String? _ne(String? s) => (s != null && s.isNotEmpty) ? s : null;
}

class BatchSummary {
  final String id;
  final String name;
  final String? description;
  final String? cone;
  final String? firingType;
  final int tileCount;
  final String dateCreated;
  final String dateModified;

  const BatchSummary({
    required this.id,
    required this.name,
    this.description,
    this.cone,
    this.firingType,
    required this.tileCount,
    required this.dateCreated,
    required this.dateModified,
  });

  factory BatchSummary.fromJson(Map<String, dynamic> j) => BatchSummary(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? 'Untitled Batch',
        description: j['description'] as String?,
        cone: j['cone'] as String?,
        firingType: j['firingType'] as String?,
        tileCount: (j['tileCount'] as num?)?.toInt() ?? 0,
        dateCreated: j['dateCreated'] as String? ?? '',
        dateModified: j['dateModified'] as String? ?? '',
      );
}

class BatchDetail {
  final String id;
  final String name;
  final String? description;
  final String? cone;
  final String? firingType;
  final int tileCount;
  final String dateCreated;
  final String dateModified;
  final List<TestTile> tiles;

  const BatchDetail({
    required this.id,
    required this.name,
    this.description,
    this.cone,
    this.firingType,
    required this.tileCount,
    required this.dateCreated,
    required this.dateModified,
    required this.tiles,
  });

  factory BatchDetail.fromJson(Map<String, dynamic> j) => BatchDetail(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? 'Untitled Batch',
        description: j['description'] as String?,
        cone: j['cone'] as String?,
        firingType: j['firingType'] as String?,
        tileCount: (j['tileCount'] as num?)?.toInt() ?? 0,
        dateCreated: j['dateCreated'] as String? ?? '',
        dateModified: j['dateModified'] as String? ?? '',
        tiles: (j['tiles'] as List<dynamic>? ?? [])
            .map((e) => TestTile.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
