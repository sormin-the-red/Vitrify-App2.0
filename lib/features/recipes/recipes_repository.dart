import 'dart:async';
import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/network/api_client.dart';
import 'recipe_models.dart';

part 'recipes_repository.g.dart';

class RecipesRepository {
  RecipesRepository(this._api);
  final ApiClient _api;

  Future<List<RecipeSummary>> listRecipes() async {
    final res = await _api.get('/recipes');
    if (res.statusCode != 200) throw Exception('Failed to load recipes');
    final body = jsonDecode(res.body);
    final list = body is List
        ? body
        : (body as Map<String, dynamic>)['recipes'] as List? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(RecipeSummary.fromJson)
        .toList();
  }

  Future<RecipeDetail> getRecipe(String id) async {
    final res = await _api.get('/recipes/$id');
    if (res.statusCode != 200) throw Exception('Failed to load recipe');
    return RecipeDetail.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<RecipeRevision>> listRevisions(String id) async {
    final res = await _api.get('/recipes/$id/revisions');
    if (res.statusCode != 200) throw Exception('Failed to load revisions');
    final body = jsonDecode(res.body);
    final list = body is List
        ? body
        : (body as Map<String, dynamic>)['revisions'] as List? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(RecipeRevision.fromJson)
        .toList();
  }

  Future<String> createRecipe({
    required String name,
    String? description,
    String? cone,
    String? firingType,
    String? notes,
    bool isPublic = false,
    List<RecipeIngredient> materials = const [],
    List<String> imageUrls = const [],
    String status = 'New',
  }) async {
    final res = await _api.post('/recipes', body: {
      'name': name,
      'description': ?description,
      'cone': ?cone,
      'firingType': ?firingType,
      'notes': ?notes,
      'public': isPublic,
      'revision': {
        'materials': materials.map((m) => m.toJson()).toList(),
        'imageUrls': imageUrls,
        'status': status,
      },
    });
    if (res.statusCode != 201) throw Exception('Failed to create recipe');
    return (jsonDecode(res.body) as Map<String, dynamic>)['id'] as String;
  }

  Future<void> updateRecipe(
    String id, {
    required String name,
    String? description,
    String? cone,
    String? firingType,
    String? notes,
    bool isPublic = false,
    required List<RecipeIngredient> materials,
    List<String> imageUrls = const [],
    String status = 'New',
  }) async {
    final res = await _api.put('/recipes/$id', body: {
      'name': name,
      'description': ?description,
      'cone': ?cone,
      'firingType': ?firingType,
      'notes': ?notes,
      'public': isPublic,
      'revision': {
        'materials': materials.map((m) => m.toJson()).toList(),
        'imageUrls': imageUrls,
        'status': status,
      },
    });
    if (res.statusCode != 200) throw Exception('Failed to update recipe');
  }

  Future<void> updateRevision(
    String id,
    int revisionNum, {
    required String name,
    String? description,
    String? cone,
    String? firingType,
    String? notes,
    bool isPublic = false,
    required List<RecipeIngredient> materials,
    List<String> imageUrls = const [],
    String status = 'New',
  }) async {
    final res = await _api.put('/recipes/$id/revisions/$revisionNum', body: {
      'name': name,
      'description': ?description,
      'cone': ?cone,
      'firingType': ?firingType,
      'notes': ?notes,
      'public': isPublic,
      'materials': materials.map((m) => m.toJson()).toList(),
      'imageUrls': imageUrls,
      'status': status,
    });
    if (res.statusCode != 200) throw Exception('Failed to update revision');
  }

  Future<void> createRevision(
    String id, {
    required String name,
    String? description,
    String? cone,
    String? firingType,
    String? notes,
    bool isPublic = false,
    required List<RecipeIngredient> materials,
    List<String> imageUrls = const [],
    String status = 'New',
  }) async {
    final res = await _api.post('/recipes/$id/revisions', body: {
      'name': name,
      'description': ?description,
      'cone': ?cone,
      'firingType': ?firingType,
      'notes': ?notes,
      'public': isPublic,
      'materials': materials.map((m) => m.toJson()).toList(),
      'imageUrls': imageUrls,
      'status': status,
    });
    if (res.statusCode != 201) throw Exception('Failed to create revision');
  }

  Future<void> deleteRecipe(String id) async {
    final res = await _api.delete('/recipes/$id');
    if (res.statusCode != 200) throw Exception('Failed to delete recipe');
  }

  Future<String> duplicateRecipe(String id) async {
    final detail = await getRecipe(id);
    final mats   = detail.revision?.materials ?? [];
    return createRecipe(
      name: '${detail.name} (Copy)',
      description: detail.description.isEmpty ? null : detail.description,
      cone:        detail.cone.isEmpty ? null : detail.cone,
      firingType:  detail.firingType.isEmpty ? null : detail.firingType,
      notes:       detail.notes.isEmpty ? null : detail.notes,
      isPublic:    false,
      materials:   mats,
      imageUrls:   detail.revision?.imageUrls ?? [],
      status:      detail.revision?.status ?? 'New',
    );
  }

  Future<List<RecipeIngredient>> generateAiRecipe({
    required String description,
    String? cone,
    String? firingType,
  }) async {
    final res = await _api.post('/ai/recipe', body: {
      'description': description,
      'cone': ?cone,
      'firingType': ?firingType,
    });
    if (res.statusCode == 429) {
      final err = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(err['error'] ?? 'Daily AI limit reached');
    }
    if (res.statusCode != 200) throw Exception('AI generation failed');
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return (body['ingredients'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(RecipeIngredient.fromJson)
        .toList();
  }

  Future<String> uploadImage(List<int> bytes, String mimeType) async {
    final res = await _api.uploadBytes('/images', bytes, mimeType);
    if (res.statusCode != 200) {
      throw Exception('Image upload failed (${res.statusCode})');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    return body['url'] as String;
  }
}

@Riverpod(keepAlive: true)
RecipesRepository recipesRepository(RecipesRepositoryRef ref) =>
    RecipesRepository(ref.watch(apiClientProvider));

@riverpod
Future<List<RecipeSummary>> recipesList(RecipesListRef ref) =>
    ref.watch(recipesRepositoryProvider).listRecipes();

@riverpod
Future<RecipeDetail> recipeDetail(RecipeDetailRef ref, String id) =>
    ref.watch(recipesRepositoryProvider).getRecipe(id);

@riverpod
Future<List<RecipeRevision>> recipeRevisions(
        RecipeRevisionsRef ref, String id) =>
    ref.watch(recipesRepositoryProvider).listRevisions(id);
