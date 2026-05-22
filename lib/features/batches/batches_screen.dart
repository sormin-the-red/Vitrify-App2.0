import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/settings/settings_provider.dart';
import 'batch_models.dart';
import 'batches_repository.dart';

class BatchesScreen extends ConsumerWidget {
  const BatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Batches'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: FilledButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Batch'),
              onPressed: () => _showCreateDialog(context, ref),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: const _BatchList(),
    );
  }

  static Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final settings = ref.read(settingsNotifierProvider);
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String? cone = settings.defaultCone;
    String? firingType = settings.defaultFiringType;

    final cones = ['022','021','020','019','018','017','016','015','014','013',
        '012','011','010','09','08','07','06','05','04','03','02','01',
        '1','2','3','4','5','6','7','8','9','10','11','12','13','14'];
    final firingTypes = ['Oxidation', 'Reduction', 'Neutral', 'Soda', 'Wood', 'Salt'];

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('New Test Batch'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name *'),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: cone,
                  hint: const Text('Cone'),
                  items: cones
                      .map((c) => DropdownMenuItem(value: c, child: Text('Cone $c')))
                      .toList(),
                  onChanged: (v) => setState(() => cone = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: firingType,
                  hint: const Text('Firing type'),
                  items: firingTypes
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(),
                  onChanged: (v) => setState(() => firingType = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  final repo = ref.read(batchesRepositoryProvider);
                  await repo.createBatch(
                    name: name,
                    description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                    cone: cone,
                    firingType: firingType,
                  );
                  ref.invalidate(batchesListProvider);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BatchList extends ConsumerWidget {
  const _BatchList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(batchesListProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text('$e'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => ref.invalidate(batchesListProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (batches) {
        if (batches.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.science_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No test batches yet.',
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
                SizedBox(height: 8),
                Text('Tap + to start tracking a new batch.',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(batchesListProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: batches.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _BatchCard(batch: batches[i], ref: ref),
          ),
        );
      },
    );
  }
}

class _BatchCard extends StatelessWidget {
  const _BatchCard({required this.batch, required this.ref});
  final BatchSummary batch;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final subtitle = [
      if (batch.cone != null) 'Cone ${batch.cone}',
      if (batch.firingType != null) batch.firingType!,
    ].join(' · ');

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/batches/${batch.id}'),
        onLongPress: () => _confirmDelete(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.tertiaryContainer,
                      scheme.tertiaryContainer.withValues(alpha: 0.55),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${batch.tileCount}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: scheme.onTertiaryContainer,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(batch.name,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(subtitle,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${batch.tileCount} tile${batch.tileCount == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete batch?'),
        content: Text('Delete "${batch.name}" and all its tiles? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error, foregroundColor: Theme.of(context).colorScheme.onError),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(batchesRepositoryProvider).deleteBatch(batch.id);
                ref.invalidate(batchesListProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
