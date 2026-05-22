import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../recipes/recipe_models.dart';
import 'mix_models.dart';
import 'mixes_repository.dart';

class MixSetupSheet extends ConsumerStatefulWidget {
  const MixSetupSheet({
    super.key,
    required this.recipe,
    required this.revision,
  });

  final RecipeDetail recipe;
  final RecipeRevision revision;

  @override
  ConsumerState<MixSetupSheet> createState() => _MixSetupSheetState();
}

class _MixSetupSheetState extends ConsumerState<MixSetupSheet> {
  final _amountCtrl = TextEditingController(text: '1000');
  final _notesCtrl = TextEditingController();
  String _unit = 'g';
  double _waterRatio = 0.45;
  bool _starting = false;

  static const _units = ['g', 'lbs', 'kg', 'oz'];
  static const _presets = [
    ('100 g',   100.0,  'g'),
    ('500 g',   500.0,  'g'),
    ('1 kg',   1000.0,  'g'),
    ('5 lbs', 2267.96, 'g'),
  ];

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _batchGrams {
    final v = double.tryParse(_amountCtrl.text) ?? 0;
    return switch (_unit) {
      'lbs' => v * 453.592,
      'kg'  => v * 1000.0,
      'oz'  => v * 28.3495,
      _     => v,
    };
  }

  double get _waterGrams => _batchGrams * _waterRatio;

  String _fmtWater() {
    final g = _waterGrams;
    return switch (_unit) {
      'lbs' => '${(g * 0.00220462).toStringAsFixed(2)} lbs',
      'kg'  => '${(g / 1000).toStringAsFixed(3)} kg',
      'oz'  => '${(g * 0.035274).toStringAsFixed(1)} oz',
      _     => '${g.toStringAsFixed(0)} g',
    };
  }

  Future<void> _start() async {
    final batchGrams = _batchGrams;
    if (batchGrams <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a batch size')));
      return;
    }
    if (batchGrams > 50000) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Batch size exceeds 50 kg — please check the value')));
      return;
    }

    setState(() => _starting = true);
    try {
      final mix = await ref.read(mixesRepositoryProvider).createMix(
            recipeId: widget.recipe.id,
            revisionNum: widget.revision.revisionNum,
            recipeName: widget.recipe.name,
            ingredients: widget.revision.materials,
            batchSizeGrams: batchGrams,
            displayUnit: _unit,
            waterRatio: _waterRatio,
            notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          );

      if (!mounted) return;
      Navigator.of(context).pop(); // close sheet
      context.push('/mix/${mix.id}', extra: mix);
    } catch (e) {
      if (mounted) {
        setState(() => _starting = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.45,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, __) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mix Glaze',
                      style: Theme.of(context).textTheme.titleLarge),
                  Text(
                    widget.recipe.name,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Batch size ─────────────────────────────────────────────
                    Text('Batch size',
                        style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _amountCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                              LengthLimitingTextInputFormatter(8),
                            ],
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _unit,
                          items: _units
                              .map((u) =>
                                  DropdownMenuItem(value: u, child: Text(u)))
                              .toList(),
                          onChanged: (v) => setState(() => _unit = v!),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Presets
                    Wrap(
                      spacing: 8,
                      children: _presets.map((p) {
                        return ActionChip(
                          label: Text(p.$1),
                          visualDensity: VisualDensity.compact,
                          onPressed: () => setState(() {
                            _amountCtrl.text =
                                p.$3 == _unit ? p.$2.toStringAsFixed(0) : _convertDisplay(p.$2, p.$3);
                            // Always store as grams target, update display value
                            _unit = p.$3;
                            _amountCtrl.text = p.$2.toStringAsFixed(0);
                          }),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // ── Water ─────────────────────────────────────────────────
                    Row(
                      children: [
                        Text('Water  ${(_waterRatio * 100).toStringAsFixed(0)}%',
                            style: Theme.of(context).textTheme.labelLarge),
                        const Spacer(),
                        Text(_fmtWater(),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: scheme.primary)),
                      ],
                    ),
                    Slider(
                      value: _waterRatio,
                      min: 0.25,
                      max: 0.75,
                      divisions: 50,
                      onChanged: (v) => setState(() => _waterRatio = v),
                    ),
                    Text(
                      '25% (thick) → 75% (thin)  ·  ~45% typical for dipping',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),

                    const SizedBox(height: 20),

                    // ── Notes ─────────────────────────────────────────────────
                    Text('Notes (optional)',
                        style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Mixing notes, special instructions…',
                        isDense: true,
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: FilledButton.icon(
                icon: _starting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.scale_outlined),
                label: const Text('Start Mixing'),
                onPressed: _starting ? null : _start,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _convertDisplay(double grams, String toUnit) {
    final v = switch (toUnit) {
      'lbs' => grams * 0.00220462,
      'kg'  => grams / 1000.0,
      'oz'  => grams * 0.035274,
      _     => grams,
    };
    return switch (toUnit) {
      'lbs' => v.toStringAsFixed(2),
      'kg'  => v.toStringAsFixed(3),
      'oz'  => v.toStringAsFixed(1),
      _     => v.toStringAsFixed(0),
    };
  }
}
