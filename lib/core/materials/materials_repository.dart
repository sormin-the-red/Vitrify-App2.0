import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'material_model.dart';

part 'materials_repository.g.dart';

const _cdnUrl   = 'https://dvzn9jjuyqawh.cloudfront.net/materials/v1.json';
const _cacheKey = 'materials_cache_v1';
const _etagKey  = 'materials_etag_v1';

class MaterialsRepository {
  Future<List<MaterialModel>> getMaterials() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);

    if (cached != null) {
      _checkForUpdate(prefs); // background, fire-and-forget
      return _parse(cached);
    }

    return _download(prefs);
  }

  Future<List<MaterialModel>> _download(SharedPreferences prefs) async {
    final response = await http.get(Uri.parse(_cdnUrl));
    if (response.statusCode != 200) {
      throw Exception('Failed to load materials (${response.statusCode})');
    }
    await prefs.setString(_cacheKey, response.body);
    final etag = response.headers['etag'];
    if (etag != null) await prefs.setString(_etagKey, etag);
    return _parse(response.body);
  }

  Future<void> _checkForUpdate(SharedPreferences prefs) async {
    final etag = prefs.getString(_etagKey);
    try {
      final response = await http.get(
        Uri.parse(_cdnUrl),
        headers: {if (etag != null) 'If-None-Match': etag},
      );
      if (response.statusCode == 200) {
        await prefs.setString(_cacheKey, response.body);
        final newEtag = response.headers['etag'];
        if (newEtag != null) await prefs.setString(_etagKey, newEtag);
      }
    } catch (_) {}
  }

  List<MaterialModel> _parse(String body) {
    final list = jsonDecode(body) as List;
    return list
        .map((e) => MaterialModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

@Riverpod(keepAlive: true)
MaterialsRepository materialsRepository(MaterialsRepositoryRef ref) =>
    MaterialsRepository();

@Riverpod(keepAlive: true)
Future<List<MaterialModel>> materials(MaterialsRef ref) =>
    ref.watch(materialsRepositoryProvider).getMaterials();
