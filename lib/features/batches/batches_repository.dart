import 'dart:async';
import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/network/api_client.dart';
import 'batch_models.dart';

part 'batches_repository.g.dart';

class BatchesRepository {
  BatchesRepository(this._api);
  final ApiClient _api;

  Future<List<BatchSummary>> listBatches() async {
    final res = await _api.get('/batches');
    if (res.statusCode != 200) throw Exception('Failed to load batches');
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return (body['batches'] as List<dynamic>? ?? [])
        .map((e) => BatchSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BatchDetail> getBatch(String id) async {
    final res = await _api.get('/batches/$id');
    if (res.statusCode != 200) throw Exception('Failed to load batch');
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return BatchDetail.fromJson(body);
  }

  Future<String> createBatch({
    required String name,
    String? description,
    String? cone,
    String? firingType,
  }) async {
    final res = await _api.post('/batches', body: {
      'name': name,
      'description': ?description,
      'cone': ?cone,
      'firingType': ?firingType,
    });
    if (res.statusCode != 201) throw Exception('Failed to create batch');
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return body['id'] as String;
  }

  Future<void> deleteBatch(String id) async {
    final res = await _api.delete('/batches/$id');
    if (res.statusCode != 200) throw Exception('Failed to delete batch');
  }

  Future<void> addTile(String batchId, {
    required List<GlazeLayer> glazeLayers,
    String? notes,
    String? outcome,
    String? atmosphere,
    String? temperature,
    List<String>? photoUrls,
    String? firingScheduleId,
  }) async {
    final res = await _api.post('/batches/$batchId/tiles', body: {
      'glazeLayers': glazeLayers.map((l) => l.toJson()).toList(),
      'notes': ?notes,
      'outcome': ?outcome,
      'atmosphere': ?atmosphere,
      'temperature': ?temperature,
      'photoUrls': ?photoUrls,
      'firingScheduleId': ?firingScheduleId,
    });
    if (res.statusCode != 201) throw Exception('Failed to add tile');
  }

  Future<void> updateTile(String batchId, int tileNum, {
    required List<GlazeLayer> glazeLayers,
    String? notes,
    String? outcome,
    String? atmosphere,
    String? temperature,
    List<String>? photoUrls,
    String? firingScheduleId,
  }) async {
    final res = await _api.put('/batches/$batchId/tiles/$tileNum', body: {
      'glazeLayers': glazeLayers.map((l) => l.toJson()).toList(),
      'notes': ?notes,
      'outcome': ?outcome,
      'atmosphere': ?atmosphere,
      'temperature': ?temperature,
      'photoUrls': ?photoUrls,
      'firingScheduleId': ?firingScheduleId,
    });
    if (res.statusCode != 200) throw Exception('Failed to update tile');
  }
}

@riverpod
BatchesRepository batchesRepository(BatchesRepositoryRef ref) =>
    BatchesRepository(ref.watch(apiClientProvider));

@riverpod
Future<List<BatchSummary>> batchesList(BatchesListRef ref) =>
    ref.watch(batchesRepositoryProvider).listBatches();

@riverpod
Future<BatchDetail> batchDetail(BatchDetailRef ref, String id) =>
    ref.watch(batchesRepositoryProvider).getBatch(id);
