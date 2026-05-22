import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/materials/materials_repository.dart';
import 'inventory_models.dart';
import 'inventory_repository.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: FilledButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
              onPressed: () => _showAddDialog(context, ref),
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
      body: const _InventoryBody(),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final qtyCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    String? selectedName;
    String unit = 'lbs';
    const units = ['lbs', 'kg', 'g', 'oz'];

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Material'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () async {
                    await showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (_) => DraggableScrollableSheet(
                        initialChildSize: 0.75,
                        minChildSize: 0.5,
                        maxChildSize: 0.95,
                        expand: false,
                        builder: (_, __) => _MaterialPickerSheet(
                          onSelected: (name) =>
                              setState(() => selectedName = name),
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Material *',
                      border: const OutlineInputBorder(),
                      suffixIcon: Icon(
                        Icons.search,
                        size: 20,
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    child: Text(
                      selectedName ?? 'Search materials…',
                      style: selectedName == null
                          ? TextStyle(
                              color:
                                  Theme.of(ctx).colorScheme.onSurfaceVariant,
                            )
                          : null,
                    ),
                  ),
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
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                          LengthLimitingTextInputFormatter(8),
                        ],
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
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    LengthLimitingTextInputFormatter(8),
                  ],
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
              onPressed: selectedName == null || selectedName!.isEmpty
                  ? null
                  : () async {
                      final name = selectedName!;
                      final qty = double.tryParse(qtyCtrl.text) ?? 0;
                      final target = double.tryParse(targetCtrl.text);
                      Navigator.of(ctx).pop();

                      final currentList =
                          ref.read(inventoryListProvider).value ?? [];
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
    qtyCtrl.dispose();
    targetCtrl.dispose();
  }
}

// ── Material picker bottom sheet ──────────────────────────────────────────────

class _MaterialPickerSheet extends ConsumerStatefulWidget {
  const _MaterialPickerSheet({required this.onSelected});
  final ValueChanged<String> onSelected;

  @override
  ConsumerState<_MaterialPickerSheet> createState() =>
      _MaterialPickerSheetState();
}

class _MaterialPickerSheetState extends ConsumerState<_MaterialPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final materialsAsync = ref.watch(materialsProvider);
    final scheme = Theme.of(context).colorScheme;

    return materialsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (allMaterials) {
        final q = _query.toLowerCase().trim();
        final filtered = q.isEmpty
            ? allMaterials
            : allMaterials
                .where((m) => m.name.toLowerCase().contains(q))
                .toList();
        final exactMatch = allMaterials
            .any((m) => m.name.toLowerCase() == q);
        final showCustom = q.isNotEmpty && !exactMatch;

        return Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search ${allMaterials.length} materials…',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length + (showCustom ? 1 : 0),
                itemBuilder: (_, i) {
                  if (showCustom && i == 0) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: scheme.secondaryContainer,
                        radius: 18,
                        child: Icon(Icons.add,
                            size: 16, color: scheme.onSecondaryContainer),
                      ),
                      title: Text('"$_query"'),
                      subtitle: const Text('Custom material'),
                      onTap: () {
                        widget.onSelected(_query.trim());
                        Navigator.of(context).pop();
                      },
                    );
                  }
                  final m = filtered[showCustom ? i - 1 : i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: scheme.surfaceContainerHighest,
                      radius: 18,
                      child: Icon(Icons.science_outlined,
                          size: 14, color: scheme.onSurfaceVariant),
                    ),
                    title: Text(m.name),
                    subtitle: m.hazardous
                        ? Text('Hazardous',
                            style: TextStyle(
                                fontSize: 11, color: scheme.error))
                        : null,
                    onTap: () {
                      widget.onSelected(m.name);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Inventory body ────────────────────────────────────────────────────────────

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
                Text('Tap Add to track your first material.',
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
                if (lowStock.isNotEmpty) const SizedBox(height: 8),
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
          content: Text('Remove "${material.name}" from your inventory?'),
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
    final fraction = (m.quantity / m.targetQuantity!).clamp(0.0, 1.0);
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
    const units = ['lbs', 'kg', 'g', 'oz'];

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
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        LengthLimitingTextInputFormatter(8),
                      ],
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
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  LengthLimitingTextInputFormatter(8),
                ],
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
                final qty =
                    double.tryParse(qtyCtrl.text) ?? material.quantity;
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
        color: isLowOrEmpty
            ? scheme.errorContainer
            : scheme.surfaceContainerHighest,
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
