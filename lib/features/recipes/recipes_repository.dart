import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
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
    List<String> color = const [],
    String? finish,
    String? surface,
    String? transparency,
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
      if (color.isNotEmpty) 'color': color,
      'finish': ?finish,
      'surface': ?surface,
      'transparency': ?transparency,
      'revision': {
        'materials': materials.map((m) => m.toJson()).toList(),
        'imageUrls': imageUrls,
        'notes': notes,
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
    List<String> color = const [],
    String? finish,
    String? surface,
    String? transparency,
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
      if (color.isNotEmpty) 'color': color,
      'finish': ?finish,
      'surface': ?surface,
      'transparency': ?transparency,
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
    List<String> color = const [],
    String? finish,
    String? surface,
    String? transparency,
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
      if (color.isNotEmpty) 'color': color,
      'finish': ?finish,
      'surface': ?surface,
      'transparency': ?transparency,
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

  Future<void> deleteRevision(String id, int revNum) async {
    final res = await _api.delete('/recipes/$id/revisions/$revNum');
    if (res.statusCode != 200) throw Exception('Failed to delete revision');
  }

  Future<String> duplicateRecipe(String id) async {
    final detail = await getRecipe(id);
    final mats   = detail.revision?.materials ?? [];
    final revNotes = detail.revision?.notes ?? '';
    final notes = revNotes.isNotEmpty ? revNotes : detail.notes;
    return createRecipe(
      name:         '${detail.name} (Copy)',
      description:  detail.description.isEmpty ? null : detail.description,
      cone:         detail.cone.isEmpty ? null : detail.cone,
      firingType:   detail.firingType.isEmpty ? null : detail.firingType,
      notes:        notes.isEmpty ? null : notes,
      isPublic:     false,
      color:        detail.color,
      finish:       detail.finish.isEmpty ? null : detail.finish,
      surface:      detail.surface.isEmpty ? null : detail.surface,
      transparency: detail.transparency.isEmpty ? null : detail.transparency,
      materials:    mats,
      imageUrls:    detail.revision?.imageUrls ?? [],
      status:       detail.revision?.status ?? 'New',
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
    // Step 1: get presigned S3 URL
    final urlRes = await _api.post('/images/upload-url', body: {'contentType': mimeType});
    if (urlRes.statusCode != 200) {
      throw Exception('Failed to get upload URL (${urlRes.statusCode})');
    }
    final urlBody = jsonDecode(urlRes.body) as Map<String, dynamic>;
    final uploadUrl = urlBody['uploadUrl'] as String;
    final key = urlBody['key'] as String;

    // Step 2: PUT directly to S3 (presigned URL — no auth header)
    final s3Res = await http.put(
      Uri.parse(uploadUrl),
      headers: {'Content-Type': mimeType},
      body: bytes,
    );
    if (s3Res.statusCode != 200) {
      throw Exception('S3 upload failed (${s3Res.statusCode})');
    }

    // Step 3: confirm upload + Rekognition moderation check
    final confirmRes = await _api.post('/images/confirm', body: {'key': key});
    if (confirmRes.statusCode == 422) {
      final err = jsonDecode(confirmRes.body) as Map<String, dynamic>;
      throw Exception(err['error'] ?? 'Image rejected by moderation');
    }
    if (confirmRes.statusCode != 200) {
      throw Exception('Image confirmation failed (${confirmRes.statusCode})');
    }
    final confirmBody = jsonDecode(confirmRes.body) as Map<String, dynamic>;
    return confirmBody['cdnUrl'] as String;
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
