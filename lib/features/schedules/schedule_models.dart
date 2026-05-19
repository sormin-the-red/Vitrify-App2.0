class FiringSegment {
  final double? lowTemp;
  final double? highTemp;
  final double? ratePerHour;
  final double? holdMinutes;
  final String? note;

  const FiringSegment({
    this.lowTemp,
    this.highTemp,
    this.ratePerHour,
    this.holdMinutes,
    this.note,
  });

  factory FiringSegment.fromJson(Map<String, dynamic> j) => FiringSegment(
        lowTemp: (j['lowTemp'] as num?)?.toDouble(),
        highTemp: (j['highTemp'] as num?)?.toDouble(),
        ratePerHour: ((j['ratePerHour'] ?? j['rate']) as num?)?.toDouble(),
        holdMinutes: ((j['holdMinutes'] ?? j['hold']) as num?)?.toDouble(),
        note: j['note'] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (lowTemp != null) 'lowTemp': lowTemp,
        if (highTemp != null) 'highTemp': highTemp,
        if (ratePerHour != null) 'ratePerHour': ratePerHour,
        if (holdMinutes != null) 'holdMinutes': holdMinutes,
        if (note != null) 'note': note,
      };
}

class ScheduleRevision {
  final int revisionNum;
  final List<FiringSegment> segments;
  final List<String> linkedRecipeIds;
  final String dateCreated;

  const ScheduleRevision({
    required this.revisionNum,
    required this.segments,
    required this.linkedRecipeIds,
    required this.dateCreated,
  });

  factory ScheduleRevision.fromJson(Map<String, dynamic> j) => ScheduleRevision(
        revisionNum: (j['revisionNum'] as num?)?.toInt() ?? 1,
        segments: (j['segments'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(FiringSegment.fromJson)
            .toList(),
        linkedRecipeIds:
            (j['linkedRecipeIds'] as List<dynamic>? ?? []).cast<String>(),
        dateCreated: j['dateCreated'] as String? ?? '',
      );
}

class ScheduleSummary {
  final String id;
  final String uid;
  final String name;
  final String tempScale;
  final String maxCone;
  final bool isPublic;
  final int likeCount;
  final int revisionCount;
  final String dateCreated;
  final String dateModified;

  const ScheduleSummary({
    required this.id,
    required this.uid,
    required this.name,
    required this.tempScale,
    required this.maxCone,
    required this.isPublic,
    required this.likeCount,
    required this.revisionCount,
    required this.dateCreated,
    required this.dateModified,
  });

  factory ScheduleSummary.fromJson(Map<String, dynamic> j) => ScheduleSummary(
        id: j['id'] as String? ?? '',
        uid: j['uid'] as String? ?? '',
        name: j['name'] as String? ?? 'Untitled Schedule',
        tempScale: j['tempScale'] as String? ?? 'F',
        maxCone: j['maxCone'] as String? ?? '',
        isPublic: j['public'] as bool? ?? false,
        likeCount: (j['likeCount'] as num?)?.toInt() ?? 0,
        revisionCount: (j['revisionCount'] as num?)?.toInt() ?? 1,
        dateCreated: j['dateCreated'] as String? ?? '',
        dateModified: j['dateModified'] as String? ?? '',
      );
}

class ScheduleDetail extends ScheduleSummary {
  final String description;
  final String notes;
  final ScheduleRevision? revision;

  const ScheduleDetail({
    required super.id,
    required super.uid,
    required super.name,
    required super.tempScale,
    required super.maxCone,
    required super.isPublic,
    required super.likeCount,
    required super.revisionCount,
    required super.dateCreated,
    required super.dateModified,
    required this.description,
    required this.notes,
    this.revision,
  });

  factory ScheduleDetail.fromJson(Map<String, dynamic> j) => ScheduleDetail(
        id: j['id'] as String? ?? '',
        uid: j['uid'] as String? ?? '',
        name: j['name'] as String? ?? 'Untitled Schedule',
        tempScale: j['tempScale'] as String? ?? 'F',
        maxCone: j['maxCone'] as String? ?? '',
        isPublic: j['public'] as bool? ?? false,
        likeCount: (j['likeCount'] as num?)?.toInt() ?? 0,
        revisionCount: (j['revisionCount'] as num?)?.toInt() ?? 1,
        dateCreated: j['dateCreated'] as String? ?? '',
        dateModified: j['dateModified'] as String? ?? '',
        description: j['description'] as String? ?? '',
        notes: j['notes'] as String? ?? '',
        revision: j['revision'] != null
            ? ScheduleRevision.fromJson(j['revision'] as Map<String, dynamic>)
            : null,
      );
}
