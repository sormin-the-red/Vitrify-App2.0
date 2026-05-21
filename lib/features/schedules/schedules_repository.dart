import 'dart:async';
import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/network/api_client.dart';
import 'schedule_models.dart';

part 'schedules_repository.g.dart';

class SchedulesRepository {
  SchedulesRepository(this._api);
  final ApiClient _api;

  Future<List<ScheduleSummary>> listSchedules() async {
    final res = await _api.get('/schedules');
    if (res.statusCode != 200) throw Exception('Failed to load schedules');
    final body = jsonDecode(res.body);
    final list = body is List ? body : (body as Map<String, dynamic>)['schedules'] as List? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(ScheduleSummary.fromJson)
        .toList();
  }

  Future<ScheduleDetail> getSchedule(String id) async {
    final res = await _api.get('/schedules/$id');
    if (res.statusCode != 200) throw Exception('Failed to load schedule');
    return ScheduleDetail.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<ScheduleRevision>> listRevisions(String id) async {
    final res = await _api.get('/schedules/$id/revisions');
    if (res.statusCode != 200) throw Exception('Failed to load revisions');
    final body = jsonDecode(res.body);
    final list = body is List
        ? body
        : (body as Map<String, dynamic>)['revisions'] as List? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(ScheduleRevision.fromJson)
        .toList();
  }

  Future<String> createSchedule({
    required String name,
    String? description,
    String? notes,
    String tempScale = 'F',
    String? maxCone,
    bool isPublic = false,
    List<FiringSegment> segments = const [],
  }) async {
    final res = await _api.post('/schedules', body: {
      'name': name,
      'description': ?description,
      'notes': ?notes,
      'tempScale': tempScale,
      'maxCone': ?maxCone,
      'public': isPublic,
      'revision': {
        'segments': segments.map((s) => s.toJson()).toList(),
        'linkedRecipeIds': [],
      },
    });
    if (res.statusCode != 201) throw Exception('Failed to create schedule');
    return (jsonDecode(res.body) as Map<String, dynamic>)['id'] as String;
  }

  Future<void> updateSchedule(String id, {
    required String name,
    String? description,
    String? notes,
    String tempScale = 'F',
    String? maxCone,
    bool isPublic = false,
    required List<FiringSegment> segments,
    List<String> linkedRecipeIds = const [],
  }) async {
    final res = await _api.put('/schedules/$id', body: {
      'name': name,
      'description': ?description,
      'notes': ?notes,
      'tempScale': tempScale,
      'maxCone': ?maxCone,
      'public': isPublic,
      'revision': {
        'segments': segments.map((s) => s.toJson()).toList(),
        'linkedRecipeIds': linkedRecipeIds,
      },
    });
    if (res.statusCode != 200) throw Exception('Failed to update schedule');
  }

  Future<void> updateRevision(String id, int revisionNum, {
    required String name,
    String? description,
    String? notes,
    String tempScale = 'F',
    String? maxCone,
    bool isPublic = false,
    required List<FiringSegment> segments,
    List<String> linkedRecipeIds = const [],
  }) async {
    final res = await _api.put('/schedules/$id/revisions/$revisionNum', body: {
      'name': name,
      'description': ?description,
      'notes': ?notes,
      'tempScale': tempScale,
      'maxCone': ?maxCone,
      'public': isPublic,
      'segments': segments.map((s) => s.toJson()).toList(),
      'linkedRecipeIds': linkedRecipeIds,
    });
    if (res.statusCode != 200) throw Exception('Failed to update revision');
  }

  Future<void> createRevision(String id, {
    required String name,
    String? description,
    String? notes,
    String tempScale = 'F',
    String? maxCone,
    bool isPublic = false,
    required List<FiringSegment> segments,
    List<String> linkedRecipeIds = const [],
  }) async {
    final res = await _api.post('/schedules/$id/revisions', body: {
      'name': name,
      'description': ?description,
      'notes': ?notes,
      'tempScale': tempScale,
      'maxCone': ?maxCone,
      'public': isPublic,
      'segments': segments.map((s) => s.toJson()).toList(),
      'linkedRecipeIds': linkedRecipeIds,
    });
    if (res.statusCode != 201) throw Exception('Failed to create revision');
  }

  Future<void> deleteSchedule(String id) async {
    final res = await _api.delete('/schedules/$id');
    if (res.statusCode != 200) throw Exception('Failed to delete schedule');
  }

  Future<String> duplicateSchedule(String id) async {
    final detail = await getSchedule(id);
    final segs = detail.revision?.segments ?? [];
    return createSchedule(
      name:        '${detail.name} (Copy)',
      description: detail.description.isEmpty ? null : detail.description,
      notes:       detail.notes.isEmpty ? null : detail.notes,
      tempScale:   detail.tempScale.isEmpty ? 'F' : detail.tempScale,
      maxCone:     detail.maxCone.isEmpty ? null : detail.maxCone,
      isPublic:    false,
      segments:    segs,
    );
  }
}

@Riverpod(keepAlive: true)
SchedulesRepository schedulesRepository(SchedulesRepositoryRef ref) =>
    SchedulesRepository(ref.watch(apiClientProvider));

@riverpod
Future<List<ScheduleSummary>> schedulesList(SchedulesListRef ref) =>
    ref.watch(schedulesRepositoryProvider).listSchedules();

@riverpod
Future<ScheduleDetail> scheduleDetail(ScheduleDetailRef ref, String id) =>
    ref.watch(schedulesRepositoryProvider).getSchedule(id);

@riverpod
Future<List<ScheduleRevision>> scheduleRevisions(
        ScheduleRevisionsRef ref, String id) =>
    ref.watch(schedulesRepositoryProvider).listRevisions(id);
