import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app.dart' show kColorPass, kColorFail, kColorPromising, kColorInteresting, kColorProblematic;
import 'batch_models.dart';
import 'batches_repository.dart';
import 'tile_editor_sheet.dart';

class BatchDetailScreen extends ConsumerWidget {
  const BatchDetailScreen({super.key, required this.batchId});
  final String batchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(batchDetailProvider(batchId));
    return async.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Test Batch')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Test Batch')),
        body: Center(child: Text('$e')),
      ),
      data: (batch) => _BatchDetailView(batch: batch),
    );
  }
}

class _BatchDetailView extends ConsumerWidget {
  const _BatchDetailView({required this.batch});
  final BatchDetail batch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = [
      if (batch.cone != null) 'Cone ${batch.cone}',
      if (batch.firingType != null) batch.firingType!,
    ].join(' · ');

    return Scaffold(
      appBar: AppBar(
        title: Text(batch.name),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: FilledButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Tile'),
              onPressed: () => _addTile(context, ref),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: meta.isNotEmpty
            ? PreferredSize(
                preferredSize: const Size.fromHeight(24),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(meta,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.white70)),
                ),
              )
            : null,
      ),
      body: batch.tiles.isEmpty
          ? Builder(builder: (context) => Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.grid_view_outlined, size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.35)),
                    const SizedBox(height: 20),
                    Text('No tiles yet.',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text('Tap + to add the first test tile.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.7)),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            ))
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(batchDetailProvider(batch.id)),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                itemCount: batch.tiles.length,
                itemBuilder: (_, i) => _TileCard(
                  tile: batch.tiles[i],
                  batchId: batch.id,
                ),
              ),
            ),
    );
  }

  Future<void> _addTile(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(batchesRepositoryProvider);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => TileEditorSheet(
        batchId: batch.id,
        nextTileNum: batch.tiles.length + 1,
        onSave: (layers, notes, outcome, atmosphere, temperature, tileName) async {
          await repo.addTile(
            batch.id,
            glazeLayers: layers,
            notes: notes,
            outcome: outcome,
            atmosphere: atmosphere,
            temperature: temperature,
            tileName: tileName,
          );
          ref.invalidate(batchDetailProvider(batch.id));
        },
      ),
    );
  }
}

class _TileCard extends ConsumerWidget {
  const _TileCard({required this.tile, required this.batchId});
  final TestTile tile;
  final String batchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _editTile(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    child: Text('${tile.tileNum}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tile.tileName ??
                              (tile.glazeLayers.isEmpty
                                  ? 'No glazes'
                                  : tile.glazeLayers
                                      .map((l) => l.recipeName ?? 'Unknown glaze')
                                      .join(' + ')),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (tile.tileName != null && tile.glazeLayers.isNotEmpty)
                          Text(
                            tile.glazeLayers
                                .map((l) => l.recipeName ?? 'Unknown glaze')
                                .join(' + '),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                  if (tile.outcome != null && tile.outcome!.isNotEmpty) _OutcomeChip(tile.outcome!),
                ],
              ),
              if (tile.glazeLayers.isNotEmpty) ...[
                const SizedBox(height: 10),
                ...tile.glazeLayers.map((l) => _LayerRow(layer: l)),
              ],
              if ((tile.atmosphere?.isNotEmpty ?? false) || (tile.temperature?.isNotEmpty ?? false)) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    if (tile.atmosphere != null)
                      _MetaChip(label: tile.atmosphere!, icon: Icons.air),
                    if (tile.temperature != null)
                      _MetaChip(label: tile.temperature!, icon: Icons.thermostat),
                  ],
                ),
              ],
              if (tile.notes != null && tile.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(tile.notes!,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editTile(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(batchesRepositoryProvider);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => TileEditorSheet(
        batchId: batchId,
        existingTile: tile,
        onSave: (layers, notes, outcome, atmosphere, temperature, tileName) async {
          await repo.updateTile(
            batchId,
            tile.tileNum,
            glazeLayers: layers,
            notes: notes,
            outcome: outcome,
            atmosphere: atmosphere,
            temperature: temperature,
            tileName: tileName,
          );
          ref.invalidate(batchDetailProvider(batchId));
        },
      ),
    );
  }
}

class _LayerRow extends StatelessWidget {
  const _LayerRow({required this.layer});
  final GlazeLayer layer;

  @override
  Widget build(BuildContext context) {
    final details = [
      if (layer.applicationMethod != null) layer.applicationMethod!,
      if (layer.coatCount != null) '${layer.coatCount}×',
      if (layer.thickness != null) layer.thickness!,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Text('${layer.layerOrder}.',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              layer.recipeName ?? 'Unknown glaze',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          if (details.isNotEmpty)
            Text(details,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _OutcomeChip extends StatelessWidget {
  const _OutcomeChip(this.outcome);
  final String outcome;

  @override
  Widget build(BuildContext context) {
    final color = switch (outcome) {
      'Pass'        => kColorPass,
      'Fail'        => kColorFail,
      'Promising'   => kColorPromising,
      'Interesting' => kColorInteresting,
      'Problematic' => kColorProblematic,
      _             => const Color(0xFF8A8A8A),
    };
    return Chip(
      label: Text(outcome),
      labelStyle: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w600, color: color),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide(color: color.withValues(alpha: 0.4), width: 0.8),
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.symmetric(horizontal: 6),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Chip(
        avatar: Icon(icon, size: 14),
        label: Text(label, style: const TextStyle(fontSize: 11)),
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      );
}
