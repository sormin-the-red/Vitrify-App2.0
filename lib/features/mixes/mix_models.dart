class _Sentinel {
  const _Sentinel();
}

const _sentinel = _Sentinel();

enum MixStatus { active, complete }

class MixMaterial {
  final String name;
  final double percentage;
  final double amountGrams;
  final bool isAddition;
  final bool checked;

  const MixMaterial({
    required this.name,
    required this.percentage,
    required this.amountGrams,
    this.isAddition = false,
    this.checked = false,
  });

  factory MixMaterial.fromJson(Map<String, dynamic> j) => MixMaterial(
        name: j['name'] as String? ?? '',
        percentage: (j['percentage'] as num? ?? 0).toDouble(),
        amountGrams: (j['amountGrams'] as num? ?? 0).toDouble(),
        isAddition: j['isAddition'] as bool? ?? false,
        checked: j['checked'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'percentage': percentage,
        'amountGrams': amountGrams,
        if (isAddition) 'isAddition': true,
        'checked': checked,
      };

  MixMaterial copyWith({bool? checked}) => MixMaterial(
        name: name,
        percentage: percentage,
        amountGrams: amountGrams,
        isAddition: isAddition,
        checked: checked ?? this.checked,
      );
}

class GlazeMix {
  final String id;
  final String recipeId;
  final int revisionNum;
  final String recipeName;
  final double batchSizeGrams;
  final String displayUnit;
  final double waterRatio;
  final double? targetSg;
  final double? achievedSg;
  final String? notes;
  final MixStatus status;
  final List<MixMaterial> materials;
  final String dateCreated;
  final String? dateCompleted;

  const GlazeMix({
    required this.id,
    required this.recipeId,
    required this.revisionNum,
    required this.recipeName,
    required this.batchSizeGrams,
    required this.displayUnit,
    required this.waterRatio,
    this.targetSg,
    this.achievedSg,
    this.notes,
    required this.status,
    required this.materials,
    required this.dateCreated,
    this.dateCompleted,
  });

  double get waterAmountGrams => batchSizeGrams * waterRatio;
  int get checkedCount => materials.where((m) => m.checked).length;
  bool get allBaseChecked =>
      materials.where((m) => !m.isAddition).every((m) => m.checked);
  List<MixMaterial> get baseMaterials =>
      materials.where((m) => !m.isAddition).toList();
  List<MixMaterial> get additionMaterials =>
      materials.where((m) => m.isAddition).toList();

  factory GlazeMix.fromJson(Map<String, dynamic> j) => GlazeMix(
        id: j['id'] as String? ?? '',
        recipeId: j['recipeId'] as String? ?? '',
        revisionNum: (j['revisionNum'] as num?)?.toInt() ?? 1,
        recipeName: j['recipeName'] as String? ?? '',
        batchSizeGrams: (j['batchSizeGrams'] as num? ?? 0).toDouble(),
        displayUnit: j['displayUnit'] as String? ?? 'g',
        waterRatio: (j['waterRatio'] as num? ?? 0.45).toDouble(),
        targetSg: (j['targetSg'] as num?)?.toDouble(),
        achievedSg: (j['achievedSg'] as num?)?.toDouble(),
        notes: j['notes'] as String?,
        status: j['status'] == 'complete' ? MixStatus.complete : MixStatus.active,
        materials: (j['materials'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(MixMaterial.fromJson)
            .toList(),
        dateCreated: j['dateCreated'] as String? ?? '',
        dateCompleted: j['dateCompleted'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'recipeId': recipeId,
        'revisionNum': revisionNum,
        'recipeName': recipeName,
        'batchSizeGrams': batchSizeGrams,
        'displayUnit': displayUnit,
        'waterRatio': waterRatio,
        if (targetSg != null) 'targetSg': targetSg,
        if (achievedSg != null) 'achievedSg': achievedSg,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
        'status': status.name,
        'materials': materials.map((m) => m.toJson()).toList(),
        'dateCreated': dateCreated,
        if (dateCompleted != null) 'dateCompleted': dateCompleted,
      };

  GlazeMix copyWith({
    List<MixMaterial>? materials,
    MixStatus? status,
    Object? achievedSg = _sentinel,
    Object? dateCompleted = _sentinel,
  }) =>
      GlazeMix(
        id: id,
        recipeId: recipeId,
        revisionNum: revisionNum,
        recipeName: recipeName,
        batchSizeGrams: batchSizeGrams,
        displayUnit: displayUnit,
        waterRatio: waterRatio,
        targetSg: targetSg,
        achievedSg:
            achievedSg == _sentinel ? this.achievedSg : achievedSg as double?,
        notes: notes,
        status: status ?? this.status,
        materials: materials ?? this.materials,
        dateCreated: dateCreated,
        dateCompleted: dateCompleted == _sentinel
            ? this.dateCompleted
            : dateCompleted as String?,
      );
}

class MixSummary {
  final String id;
  final double batchSizeGrams;
  final String displayUnit;
  final int revisionNum;
  final MixStatus status;
  final String dateCreated;
  final String? dateCompleted;
  final int checkedCount;
  final int totalCount;

  const MixSummary({
    required this.id,
    required this.batchSizeGrams,
    required this.displayUnit,
    this.revisionNum = 1,
    required this.status,
    required this.dateCreated,
    this.dateCompleted,
    required this.checkedCount,
    required this.totalCount,
  });

  factory MixSummary.fromJson(Map<String, dynamic> j) => MixSummary(
        id: j['id'] as String? ?? '',
        batchSizeGrams: (j['batchSizeGrams'] as num? ?? 0).toDouble(),
        displayUnit: j['displayUnit'] as String? ?? 'g',
        revisionNum: (j['revisionNum'] as num?)?.toInt() ?? 1,
        status:
            j['status'] == 'complete' ? MixStatus.complete : MixStatus.active,
        dateCreated: j['dateCreated'] as String? ?? '',
        dateCompleted: j['dateCompleted'] as String?,
        checkedCount: (j['checkedCount'] as num?)?.toInt() ?? 0,
        totalCount: (j['totalCount'] as num?)?.toInt() ?? 0,
      );
}
