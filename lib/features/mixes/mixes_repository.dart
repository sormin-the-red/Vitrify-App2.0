import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/network/api_client.dart';
import '../recipes/recipe_models.dart';
import 'mix_models.dart';

part 'mixes_repository.g.dart';

class MixesRepository {
  MixesRepository(this._api);
  final ApiClient _api;

  Future<GlazeMix> createMix({
    required String recipeId,
    required int revisionNum,
    required String recipeName,
    required List<RecipeIngredient> ingredients,
    required double batchSizeGrams,
    required String displayUnit,
    required double waterRatio,
    double? targetSg,
    String? notes,
  }) async {
    final basePct = ingredients
        .where((m) => !m.isAddition)
        .fold<double>(0, (s, m) => s + m.percentage);
    final addPct = ingredients
        .where((m) => m.isAddition)
        .fold<double>(0, (s, m) => s + m.percentage);

    final materials = ingredients.map((ing) {
      final totalPct = ing.isAddition ? addPct : basePct;
      final amount =
          totalPct > 0 ? batchSizeGrams * ing.percentage / totalPct : 0.0;
      return {
        'name': ing.name,
        'percentage': ing.percentage,
        'amountGrams': amount,
        if (ing.isAddition) 'isAddition': true,
        'checked': false,
      };
    }).toList();

    final res = await _api.post('/mixes', body: {
      'recipeId': recipeId,
      'revisionNum': revisionNum,
      'recipeName': recipeName,
      'batchSizeGrams': batchSizeGrams,
      'displayUnit': displayUnit,
      'waterRatio': waterRatio,
      if (targetSg != null) 'targetSg': targetSg,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'materials': materials,
    });

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Failed to create mix (${res.statusCode})');
    }
    return GlazeMix.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<GlazeMix> getMix(String id) async {
    final res = await _api.get('/mixes/$id');
    if (res.statusCode != 200) throw Exception('Failed to load mix');
    return GlazeMix.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<GlazeMix> updateMix(GlazeMix mix) async {
    final res = await _api.put('/mixes/${mix.id}', body: mix.toJson());
    if (res.statusCode != 200) throw Exception('Failed to save mix');
    return GlazeMix.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> deleteMix(String id) async {
    final res = await _api.delete('/mixes/$id');
    if (res.statusCode != 200) throw Exception('Failed to delete mix');
  }

  Future<List<MixSummary>> getMixesForRecipe(String recipeId) async {
    final res = await _api.get('/mixes?recipeId=$recipeId');
    if (res.statusCode != 200) throw Exception('Failed to load mix history');
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return (body['mixes'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(MixSummary.fromJson)
        .toList();
  }
}

@Riverpod(keepAlive: true)
MixesRepository mixesRepository(MixesRepositoryRef ref) =>
    MixesRepository(ref.watch(apiClientProvider));

@riverpod
Future<GlazeMix> mixDetail(MixDetailRef ref, String id) =>
    ref.watch(mixesRepositoryProvider).getMix(id);

@riverpod
Future<List<MixSummary>> recipeMixes(RecipeMixesRef ref, String recipeId) =>
    ref.watch(mixesRepositoryProvider).getMixesForRecipe(recipeId);
