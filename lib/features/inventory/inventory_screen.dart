import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_gate.dart';
import 'inventory_models.dart';
import 'inventory_repository.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuthGate(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Inventory'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.push('/settings'),
            ),
          ],
        ),
        body: const _InventoryBody(),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddDialog(context, ref),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    String unit = 'lbs';
    final units = ['lbs', 'kg', 'g', 'oz'];

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Material'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Material name *',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: qtyCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: unit,
                      items: units
                          .map((u) =>
                              DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                      onChanged: (v) => setState(() => unit = v!),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: targetCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Target quantity (optional)',
                    border: OutlineInputBorder(),
                    helperText: 'Used for low-stock alerts',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final qty = double.tryParse(qtyCtrl.text) ?? 0;
                final target = double.tryParse(targetCtrl.text);
                Navigator.of(ctx).pop();

                final currentList = ref.read(inventoryListProvider).value ?? [];
                final updated = [
                  ...currentList,
                  InventoryMaterial(
                    name: name,
                    quantity: qty,
                    unit: unit,
                    targetQuantity: target,
                  ),
                ];
                try {
                  await ref
                      .read(inventoryRepositoryProvider)
                      .saveInventory(updated);
                  ref.invalidate(inventoryListProvider);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    nameCtrl.dispose();
    qtyCtrl.dispose();
    targetCtrl.dispose();
  }
}

class _InventoryBody extends ConsumerWidget {
  const _InventoryBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(inventoryListProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (materials) {
        if (materials.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inventory_2_outlined, size: 56, color: Colors.grey),
                SizedBox(height: 12),
                Text('No materials yet.',
                    style: TextStyle(color: Colors.grey)),
                SizedBox(height: 4),
                Text('Tap + to add your first material.',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          );
        }

        final lowStock = materials.where((m) => m.isLow || m.isEmpty).toList();
        final normal = materials.where((m) => !m.isLow && !m.isEmpty).toList();

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(inventoryListProvider),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 88),
            children: [
              if (lowStock.isNotEmpty) ...[
                _SectionHeader(
                  label: 'Low / Empty',
                  icon: Icons.warning_amber_rounded,
                  color: Theme.of(context).colorScheme.error,
                ),
                ...lowStock.map((m) => _MaterialTile(
                      material: m,
                      allMaterials: materials,
                    )),
              ],
              if (normal.isNotEmpty) ...[
                if (lowStock.isNotEmpty)
                  const SizedBox(height: 8),
                const _SectionHeader(
                  label: 'In Stock',
                  icon: Icons.check_circle_outline,
                ),
                ...normal.map((m) => _MaterialTile(
                      material: m,
                      allMaterials: materials,
                    )),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.icon, this.color});
  final String label;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: effectiveColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: effectiveColor),
          ),
        ],
      ),
    );
  }
}

class _MaterialTile extends ConsumerWidget {
  const _MaterialTile({required this.material, required this.allMaterials});
  final InventoryMaterial material;
  final List<InventoryMaterial> allMaterials;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isLowOrEmpty = material.isLow || material.isEmpty;

    return Dismissible(
      key: Key(material.name),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: scheme.errorContainer,
        child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
      ),
      confirmDismiss: (_) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Remove material?'),
          content: Text(
              'Remove "${material.name}" from your inventory?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Remove')),
          ],
        ),
      ),
      onDismissed: (_) async {
        final updated =
            allMaterials.where((m) => m.name != material.name).toList();
        try {
          await ref
              .read(inventoryRepositoryProvider)
              .saveInventory(updated);
          ref.invalidate(inventoryListProvider);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('Error: $e')));
          }
        }
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isLowOrEmpty
              ? scheme.errorContainer
              : scheme.secondaryContainer,
          child: Icon(
            material.isEmpty
                ? Icons.remove_circle_outline
                : Icons.science_outlined,
            size: 18,
            color: isLowOrEmpty
                ? scheme.onErrorContainer
                : scheme.onSecondaryContainer,
          ),
        ),
        title: Text(material.name),
        subtitle: _buildSubtitle(context, material),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _QuantityChip(material: material),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              visualDensity: VisualDensity.compact,
              onPressed: () =>
                  _showEditDialog(context, ref, material, allMaterials),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildSubtitle(BuildContext context, InventoryMaterial m) {
    if (m.targetQuantity == null || m.targetQuantity! <= 0) return null;
    final fraction =
        (m.quantity / m.targetQuantity!).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(top: 4, right: 48),
      child: LinearProgressIndicator(
        value: fraction,
        minHeight: 4,
        borderRadius: BorderRadius.circular(2),
        color: m.isLow
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    InventoryMaterial material,
    List<InventoryMaterial> allMaterials,
  ) async {
    final qtyCtrl =
        TextEditingController(text: material.quantity.toStringAsFixed(2));
    final targetCtrl = TextEditingController(
        text: material.targetQuantity != null
            ? material.targetQuantity!.toStringAsFixed(2)
            : '');
    String unit = material.unit;
    final units = ['lbs', 'kg', 'g', 'oz'];

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(material.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: qtyCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      autofocus: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: unit,
                    items: units
                        .map((u) =>
                            DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (v) => setState(() => unit = v!),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: targetCtrl,
                decoration: const InputDecoration(
                  labelText: 'Target quantity',
                  border: OutlineInputBorder(),
                  helperText: 'Low-stock threshold',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final qty = double.tryParse(qtyCtrl.text) ?? material.quantity;
                final target = double.tryParse(targetCtrl.text);
                Navigator.of(ctx).pop();

                final updated = allMaterials.map((m) {
                  if (m.name == material.name) {
                    return m.copyWith(
                        quantity: qty, unit: unit, targetQuantity: target);
                  }
                  return m;
                }).toList();
                try {
                  await ref
                      .read(inventoryRepositoryProvider)
                      .saveInventory(updated);
                  ref.invalidate(inventoryListProvider);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    qtyCtrl.dispose();
    targetCtrl.dispose();
  }
}

class _QuantityChip extends StatelessWidget {
  const _QuantityChip({required this.material});
  final InventoryMaterial material;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLowOrEmpty = material.isLow || material.isEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isLowOrEmpty ? scheme.errorContainer : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${_fmtQty(material.quantity)} ${material.unit}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isLowOrEmpty ? scheme.onErrorContainer : scheme.onSurface,
        ),
      ),
    );
  }

  String _fmtQty(double v) =>
      v == v.truncate() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}
