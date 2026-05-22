import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../inventory/inventory_models.dart';
import '../inventory/inventory_repository.dart';
import 'mix_models.dart';
import 'mixes_repository.dart';

// ── Unit helpers ──────────────────────────────────────────────────────────────

double _toUnit(double grams, String unit) => switch (unit) {
      'lbs' => grams * 0.00220462,
      'kg' => grams / 1000.0,
      'oz' => grams * 0.035274,
      _ => grams,
    };

double _invToGrams(double amount, String unit) => switch (unit) {
      'lbs' => amount * 453.592,
      'kg' => amount * 1000.0,
      'oz' => amount * 28.3495,
      _ => amount,
    };

String _fmtAmount(double grams, String unit) {
  final v = _toUnit(grams, unit);
  return switch (unit) {
    'lbs' => '${v.toStringAsFixed(2)} lbs',
    'kg' => '${v.toStringAsFixed(3)} kg',
    'oz' => '${v.toStringAsFixed(1)} oz',
    _ => '${v.toStringAsFixed(1)} g',
  };
}

// ── Inventory status ──────────────────────────────────────────────────────────

enum _InvStatus { sufficient, low, empty, missing }

_InvStatus _checkInv(
    String name, double neededGrams, List<InventoryMaterial> inv) {
  final match = inv.where(
      (m) => m.name.toLowerCase() == name.toLowerCase());
  if (match.isEmpty) return _InvStatus.missing;
  final item = match.first;
  if (item.isEmpty) return _InvStatus.empty;
  final haveGrams = _invToGrams(item.quantity, item.unit);
  if (haveGrams >= neededGrams) return _InvStatus.sufficient;
  return _InvStatus.low;
}

Color _invColor(BuildContext context, _InvStatus s) =>
    switch (s) {
      _InvStatus.sufficient => Colors.green.shade400,
      _InvStatus.low => Colors.amber.shade600,
      _InvStatus.empty => Theme.of(context).colorScheme.error,
      _InvStatus.missing => Theme.of(context).colorScheme.outlineVariant,
    };

String _invTooltip(_InvStatus s) => switch (s) {
      _InvStatus.sufficient => 'Enough in inventory',
      _InvStatus.low => 'Inventory low',
      _InvStatus.empty => 'None in inventory',
      _InvStatus.missing => 'Not tracked in inventory',
    };

// ── Screen ────────────────────────────────────────────────────────────────────

class MixSessionScreen extends ConsumerStatefulWidget {
  const MixSessionScreen({
    super.key,
    required this.mixId,
    this.initialMix,
  });

  final String mixId;
  final GlazeMix? initialMix;

  @override
  ConsumerState<MixSessionScreen> createState() => _MixSessionScreenState();
}

class _MixSessionScreenState extends ConsumerState<MixSessionScreen> {
  GlazeMix? _mix;
  bool _saving = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _mix = widget.initialMix;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _toggle(int index) {
    final current = _mix;
    if (current == null) return;
    final updated = List<MixMaterial>.from(current.materials);
    updated[index] = updated[index].copyWith(checked: !updated[index].checked);
    setState(() => _mix = current.copyWith(materials: updated));
    _scheduleSave();
  }

  void _scheduleSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 1), _save);
  }

  Future<void> _save() async {
    final mix = _mix;
    if (mix == null) return;
    setState(() => _saving = true);
    try {
      final saved = await ref.read(mixesRepositoryProvider).updateMix(mix);
      if (mounted) setState(() { _mix = saved; _saving = false; });
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _completeMix() async {
    final mix = _mix;
    if (mix == null) return;

    final sgCtrl = TextEditingController();
    bool consumeInventory = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Complete Mix'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: sgCtrl,
                decoration: const InputDecoration(
                  labelText: 'Achieved SG (optional)',
                  hintText: '1.40',
                  helperText: 'Typical range: 1.25–1.80',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  LengthLimitingTextInputFormatter(5),
                ],
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: consumeInventory,
                onChanged: (v) => setState(() => consumeInventory = v ?? false),
                title: const Text('Consume materials from inventory'),
                subtitle: const Text('Subtract weighed amounts'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Complete')),
          ],
        ),
      ),
    );

    final sgText = sgCtrl.text;
    sgCtrl.dispose();
    if (confirmed != true || !mounted) return;

    final sg = double.tryParse(sgText);
    if (sg != null && (sg < 1.0 || sg > 2.5)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SG should be between 1.00 and 2.50')),
      );
      return;
    }
    final completed = mix.copyWith(
      status: MixStatus.complete,
      achievedSg: sg,
      dateCompleted: DateTime.now().toIso8601String(),
    );

    setState(() => _saving = true);
    try {
      final saved =
          await ref.read(mixesRepositoryProvider).updateMix(completed);

      if (consumeInventory && mounted) {
        final items = mix.materials
            .map((m) => (name: m.name, quantity: m.amountGrams))
            .toList();
        await ref.read(inventoryRepositoryProvider).consume(items);
        ref.invalidate(inventoryListProvider);
      }

      if (mounted) {
        setState(() { _mix = saved; _saving = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mix complete!${sg != null ? '  SG $sg' : ''}'),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fall back to provider if we navigated without extra
    if (_mix == null) {
      final async = ref.watch(mixDetailProvider(widget.mixId));
      return async.when(
        loading: () => Scaffold(
            appBar: AppBar(title: const Text('Mix')),
            body: const Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(
            appBar: AppBar(title: const Text('Mix')),
            body: Center(child: Text('$e'))),
        data: (mix) {
          WidgetsBinding.instance.addPostFrameCallback(
              (_) => setState(() => _mix = mix));
          return _buildBody(mix);
        },
      );
    }
    return _buildBody(_mix!);
  }

  Widget _buildBody(GlazeMix mix) {
    final scheme = Theme.of(context).colorScheme;
    final inventory = ref.watch(inventoryListProvider).value ?? [];
    final total = mix.materials.length;
    final checked = mix.checkedCount;
    final isComplete = mix.status == MixStatus.complete;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(mix.recipeName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text(
              _fmtAmount(mix.batchSizeGrams, mix.displayUnit),
              style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurface.withValues(alpha: 0.7)),
            ),
          ],
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: checked == total
                  ? Colors.green.shade400
                  : scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$checked / $total',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: checked == total
                    ? Colors.white
                    : scheme.onSecondaryContainer,
              ),
            ),
          ),
          if (!isComplete) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
              child: FilledButton(
                onPressed: mix.allBaseChecked ? _completeMix : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Complete'),
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Chip(
                label: const Text('Done'),
                backgroundColor: Colors.green.shade400,
                labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Progress bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: total > 0 ? checked / total : 0,
                  minHeight: 6,
                  backgroundColor: scheme.surfaceContainerHighest,
                  color: checked == total
                      ? Colors.green.shade400
                      : scheme.primary,
                ),
              ),
            ),
          ),

          // Base materials
          if (mix.baseMaterials.isNotEmpty) ...[
            _sectionHeader(context, 'Base Recipe'),
            SliverList.builder(
              itemCount: mix.baseMaterials.length,
              itemBuilder: (_, i) {
                final globalIdx = mix.materials.indexOf(mix.baseMaterials[i]);
                return _MaterialRow(
                  material: mix.baseMaterials[i],
                  unit: mix.displayUnit,
                  invStatus: _checkInv(
                      mix.baseMaterials[i].name,
                      mix.baseMaterials[i].amountGrams,
                      inventory),
                  isComplete: isComplete,
                  onToggle: () => _toggle(globalIdx),
                );
              },
            ),
          ],

          // Additions
          if (mix.additionMaterials.isNotEmpty) ...[
            _sectionHeader(context, 'Additions'),
            SliverList.builder(
              itemCount: mix.additionMaterials.length,
              itemBuilder: (_, i) {
                final globalIdx =
                    mix.materials.indexOf(mix.additionMaterials[i]);
                return _MaterialRow(
                  material: mix.additionMaterials[i],
                  unit: mix.displayUnit,
                  invStatus: _checkInv(
                      mix.additionMaterials[i].name,
                      mix.additionMaterials[i].amountGrams,
                      inventory),
                  isComplete: isComplete,
                  onToggle: () => _toggle(globalIdx),
                );
              },
            ),
          ],

          // Water
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
              child: Text('Water',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant)),
            ),
          ),
          SliverToBoxAdapter(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: scheme.tertiaryContainer,
                child: Icon(Icons.water_drop_outlined,
                    size: 18, color: scheme.onTertiaryContainer),
              ),
              title: const Text('Water'),
              subtitle: mix.targetSg != null
                  ? Text('Target SG: ${mix.targetSg!.toStringAsFixed(2)}')
                  : null,
              trailing: Text(
                _fmtAmount(mix.waterAmountGrams, mix.displayUnit),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600, color: scheme.primary),
              ),
            ),
          ),

          // Notes
          if (mix.notes != null && mix.notes!.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Text(mix.notes!,
                      style: Theme.of(context).textTheme.bodySmall),
                ),
              ),
            ),

          // Achieved SG (post-complete)
          if (mix.achievedSg != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Icon(Icons.opacity_outlined,
                        size: 16, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text('Achieved SG: ${mix.achievedSg!.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),

          // Inventory legend
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  _legendDot(context, Colors.green.shade400, 'Sufficient'),
                  _legendDot(context, Colors.amber.shade600, 'Low'),
                  _legendDot(context, Theme.of(context).colorScheme.error, 'Empty'),
                  _legendDot(context, Theme.of(context).colorScheme.outlineVariant, 'Not tracked'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliverToBoxAdapter _sectionHeader(BuildContext context, String label) =>
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      );

  Widget _legendDot(BuildContext context, Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      );
}

// ── Material row ──────────────────────────────────────────────────────────────

class _MaterialRow extends StatelessWidget {
  const _MaterialRow({
    required this.material,
    required this.unit,
    required this.invStatus,
    required this.isComplete,
    required this.onToggle,
  });

  final MixMaterial material;
  final String unit;
  final _InvStatus invStatus;
  final bool isComplete;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDone = material.checked;

    return InkWell(
      onTap: isComplete ? null : onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Big checkbox
            GestureDetector(
              onTap: isComplete ? null : onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isDone ? scheme.primary : Colors.transparent,
                  border: Border.all(
                    color: isDone ? scheme.primary : scheme.outline,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: isDone
                    ? const Icon(Icons.check, size: 18, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 14),

            // Name
            Expanded(
              child: Text(
                material.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                  color: isDone ? scheme.onSurfaceVariant : null,
                ),
              ),
            ),

            // Inventory dot
            Tooltip(
              message: _invTooltip(invStatus),
              child: Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: _invColor(context, invStatus),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Amount
            Text(
              _fmtAmount(material.amountGrams, unit),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDone ? scheme.onSurfaceVariant : scheme.primary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
