import 'package:flutter/material.dart';

import 'batch_models.dart';

typedef TileSaveCallback = Future<void> Function(
  List<GlazeLayer> layers,
  String? notes,
  String? outcome,
  String? atmosphere,
  String? temperature,
);

class TileEditorSheet extends StatefulWidget {
  const TileEditorSheet({
    super.key,
    required this.batchId,
    this.existingTile,
    required this.onSave,
  });

  final String batchId;
  final TestTile? existingTile;
  final TileSaveCallback onSave;

  @override
  State<TileEditorSheet> createState() => _TileEditorSheetState();
}

class _TileEditorSheetState extends State<TileEditorSheet> {
  static const _outcomes = ['Pass', 'Fail', 'Promising', 'Interesting', 'Problematic'];
  static const _atmospheres = ['Oxidation', 'Reduction', 'Neutral', 'Soda', 'Wood', 'Salt'];

  // One entry per layer — parallel to _layerData
  final List<_LayerState> _layerStates = [];
  String? _outcome;
  String? _atmosphere;
  final _notesCtrl = TextEditingController();
  final _tempCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final tile = widget.existingTile;
    if (tile != null) {
      for (final layer in tile.glazeLayers) {
        _layerStates.add(_LayerState.fromLayer(layer));
      }
      _outcome = tile.outcome;
      _atmosphere = tile.atmosphere;
      _notesCtrl.text = tile.notes ?? '';
      _tempCtrl.text = tile.temperature ?? '';
    }
  }

  @override
  void dispose() {
    for (final s in _layerStates) {
      s.dispose();
    }
    _notesCtrl.dispose();
    _tempCtrl.dispose();
    super.dispose();
  }

  List<GlazeLayer> get _buildLayers => _layerStates
      .asMap()
      .entries
      .map((e) => e.value.toLayer(e.key + 1))
      .toList();

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingTile != null;
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  isEdit ? 'Tile #${widget.existingTile!.tileNum}' : 'New Tile',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                TextButton(
                  onPressed: Navigator.of(context).pop,
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                // ── Glaze layers ──────────────────────────────────────────────
                Row(
                  children: [
                    Text('Glaze Layers',
                        style: Theme.of(context).textTheme.titleMedium),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _addLayer,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Layer'),
                    ),
                  ],
                ),
                if (_layerStates.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No glaze layers added.',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  )
                else
                  Column(
                    children: _layerStates.asMap().entries.map((entry) {
                      final i = entry.key;
                      final s = entry.value;
                      return _LayerEditorCard(
                        key: s.key,
                        layerNum: i + 1,
                        state: s,
                        onChanged: () => setState(() {}),
                        onRemove: () => setState(() => _layerStates.removeAt(i)),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),

                // ── Outcome ───────────────────────────────────────────────────
                Text('Outcome', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _outcomes
                      .map((o) => ChoiceChip(
                            label: Text(o),
                            selected: _outcome == o,
                            onSelected: (_) =>
                                setState(() => _outcome = _outcome == o ? null : o),
                          ))
                      .toList(),
                ),

                const SizedBox(height: 20),

                // ── Atmosphere ────────────────────────────────────────────────
                Text('Atmosphere', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _atmospheres
                      .map((a) => ChoiceChip(
                            label: Text(a),
                            selected: _atmosphere == a,
                            onSelected: (_) =>
                                setState(() => _atmosphere = _atmosphere == a ? null : a),
                          ))
                      .toList(),
                ),

                const SizedBox(height: 20),

                // ── Temperature ───────────────────────────────────────────────
                TextField(
                  controller: _tempCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Temperature (optional)',
                    hintText: 'e.g. 2300°F or 1260°C',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Notes ─────────────────────────────────────────────────────
                TextField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Observations, surface quality, color, texture...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                ),

                const SizedBox(height: 28),

                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(isEdit ? 'Save Changes' : 'Add Tile'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addLayer() {
    setState(() => _layerStates.add(_LayerState()));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onSave(
        _buildLayers,
        _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        _outcome,
        _atmosphere,
        _tempCtrl.text.trim().isEmpty ? null : _tempCtrl.text.trim(),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// Holds mutable state for a single layer — lives in the parent State list
class _LayerState {
  final Key key = UniqueKey();
  final TextEditingController nameCtrl;
  final TextEditingController coatCtrl;
  String? applicationMethod;
  String? thickness;

  _LayerState()
      : nameCtrl = TextEditingController(),
        coatCtrl = TextEditingController();

  _LayerState.fromLayer(GlazeLayer layer)
      : nameCtrl = TextEditingController(text: layer.recipeName ?? ''),
        coatCtrl = TextEditingController(
            text: layer.coatCount != null ? '${layer.coatCount}' : ''),
        applicationMethod = layer.applicationMethod,
        thickness = layer.thickness;

  GlazeLayer toLayer(int order) => GlazeLayer(
        layerOrder: order,
        recipeName: nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
        coatCount: int.tryParse(coatCtrl.text.trim()),
        applicationMethod: applicationMethod,
        thickness: thickness,
      );

  void dispose() {
    nameCtrl.dispose();
    coatCtrl.dispose();
  }
}

class _LayerEditorCard extends StatelessWidget {
  const _LayerEditorCard({
    super.key,
    required this.layerNum,
    required this.state,
    required this.onChanged,
    required this.onRemove,
  });

  final int layerNum;
  final _LayerState state;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  static const _applicationMethods = ['Brush', 'Dip', 'Spray', 'Pour', 'Other'];
  static const _thicknesses = ['Thin', 'Medium', 'Thick'];

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  child: Text('$layerNum', style: const TextStyle(fontSize: 11)),
                ),
                const SizedBox(width: 8),
                const Text('Layer', style: TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onRemove,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: state.nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Glaze name',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: state.coatCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Coats',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: state.applicationMethod,
                    decoration: const InputDecoration(
                      labelText: 'Method',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: _applicationMethods
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) {
                      state.applicationMethod = v;
                      onChanged();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text('Thickness: ',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: 4),
                ..._thicknesses.map((t) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(t, style: const TextStyle(fontSize: 12)),
                        selected: state.thickness == t,
                        visualDensity: VisualDensity.compact,
                        onSelected: (_) {
                          state.thickness = state.thickness == t ? null : t;
                          onChanged();
                        },
                      ),
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
