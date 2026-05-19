import 'dart:async';
import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/network/api_client.dart';
import 'inventory_models.dart';

part 'inventory_repository.g.dart';

class InventoryRepository {
  InventoryRepository(this._api);
  final ApiClient _api;

  Future<List<InventoryMaterial>> getInventory() async {
    final res = await _api.get('/inventory');
    if (res.statusCode != 200) throw Exception('Failed to load inventory');
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = body['materials'] as List<dynamic>? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(InventoryMaterial.fromJson)
        .toList();
  }

  Future<void> saveInventory(List<InventoryMaterial> materials) async {
    final res = await _api.put('/inventory',
        body: {'materials': materials.map((m) => m.toJson()).toList()});
    if (res.statusCode != 200) throw Exception('Failed to save inventory');
  }

  Future<void> consume(List<({String name, double quantity})> items) async {
    final res = await _api.post('/inventory/consume', body: {
      'materials':
          items.map((i) => {'name': i.name, 'quantity': i.quantity}).toList(),
    });
    if (res.statusCode != 200) throw Exception('Failed to consume materials');
  }
}

@Riverpod(keepAlive: true)
InventoryRepository inventoryRepository(InventoryRepositoryRef ref) =>
    InventoryRepository(ref.watch(apiClientProvider));

@riverpod
Future<List<InventoryMaterial>> inventoryList(InventoryListRef ref) =>
    ref.watch(inventoryRepositoryProvider).getInventory();
