import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/settings_provider.dart';
import '../recipes/recipe_models.dart';
import '../recipes/recipes_repository.dart';
import 'batch_models.dart';

typedef TileSaveCallback = Future<void> Function(
  List<GlazeLayer> layers,
  String? notes,
  String? outcome,
  String? atmosphere,
  String? temperature,
  String? tileName,
);

class TileEditorSheet extends ConsumerStatefulWidget {
  const TileEditorSheet({
    super.key,
    required this.batchId,
    this.existingTile,
    this.nextTileNum,
    required this.onSave,
  });

  final String batchId;
  final TestTile? existingTile;
  final int? nextTileNum;
  final TileSaveCallback onSave;

  @override
  ConsumerState<TileEditorSheet> createState() => _TileEditorSheetState();
}

class _TileEditorSheetState extends ConsumerState<TileEditorSheet> {
  static const _outcomes = ['Pass', 'Fail', 'Promising', 'Interesting', 'Problematic'];
  static const _atmospheres = ['Oxidation', 'Reduction', 'Neutral', 'Soda', 'Wood', 'Salt'];

  final List<_LayerState> _layerStates = [];
  String? _outcome;
  String? _atmosphere;
  final _notesCtrl = TextEditingController();
  final _tempCtrl = TextEditingController();
  final _tileNameCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final tile = widget.existingTile;
    if (tile != null) {
      _tileNameCtrl.text = tile.tileName ?? '#${tile.tileNum}';
      for (final layer in tile.glazeLayers) {
        _layerStates.add(_LayerState.fromLayer(layer));
      }
      _outcome    = tile.outcome;
      _atmosphere = tile.atmosphere;
      _notesCtrl.text = tile.notes ?? '';
      _tempCtrl.text  = tile.temperature ?? '';
    } else {
      _tileNameCtrl.text =
          widget.nextTileNum != null ? '#${widget.nextTileNum}' : '';
      // Pre-apply atmosphere default for new tiles (empty string = no default).
      final settings = ref.read(settingsNotifierProvider);
      if (settings.defaultAtmosphere.isNotEmpty) {
        _atmosphere = settings.defaultAtmosphere;
      }
    }
  }

  @override
  void dispose() {
    for (final s in _layerStates) {
      s.dispose();
    }
    _notesCtrl.dispose();
    _tempCtrl.dispose();
    _tileNameCtrl.dispose();
    super.dispose();
  }

  List<GlazeLayer> get _buildLayers => _layerStates
      .asMap()
      .entries
      .map((e) => e.value.toLayer(e.key + 1))
      .toList();

  Future<void> _pickRecipeForLayer(_LayerState layer) async {
    final result = await showModalBottomSheet<RecipeSummary>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _RecipePickerSheet(),
    );
    if (result == null || !mounted) return;
    setState(() {
      layer.recipeId = result.id;
      layer.revisionNum = result.revisionCount;
      layer.recipeName = result.name;
    });
  }

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
            padding: const EdgeInsets.fromLTRB(16, 0, 4, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tileNameCtrl,
                    decoration: InputDecoration(
                      hintText: isEdit
                          ? '#${widget.existingTile!.tileNum}'
                          : 'Name (e.g. #${widget.nextTileNum ?? 1})',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: Theme.of(context).textTheme.titleLarge,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                TextButton(
                  onPressed: Navigator.of(context).pop,
                  child: const Text('Cancel'),
                ),
                if (_saving)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  TextButton(
                    onPressed: _save,
                    child: Text(
                      isEdit ? 'Save' : 'Add',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
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
                        onPickRecipe: () => _pickRecipeForLayer(s),
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
                  maxLength: 20,
                  decoration: const InputDecoration(
                    labelText: 'Temperature (optional)',
                    hintText: 'e.g. 2300°F or 1260°C',
                    border: OutlineInputBorder(),
                    counterText: '',
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

                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addLayer() {
    final settings = ref.read(settingsNotifierProvider);
    setState(() => _layerStates.add(
        _LayerState(defaultMethod: settings.defaultApplicationMethod)));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final tileName = _tileNameCtrl.text.trim().isEmpty
          ? null
          : _tileNameCtrl.text.trim();
      await widget.onSave(
        _buildLayers,
        _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        _outcome,
        _atmosphere,
        _tempCtrl.text.trim().isEmpty ? null : _tempCtrl.text.trim(),
        tileName,
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

// ── Layer state ───────────────────────────────────────────────────────────────

class _LayerState {
  final Key key = UniqueKey();
  String? recipeId;
  int? revisionNum;
  String? recipeName;
  final TextEditingController coatCtrl;
  String? applicationMethod;
  String? thickness;

  _LayerState({String? defaultMethod})
      : coatCtrl = TextEditingController(text: '1'),
        applicationMethod = defaultMethod;

  _LayerState.fromLayer(GlazeLayer layer)
      : recipeId = layer.recipeId,
        revisionNum = layer.revisionNum,
        recipeName = layer.recipeName,
        coatCtrl = TextEditingController(text: '${layer.coatCount ?? 1}'),
        applicationMethod = layer.applicationMethod,
        thickness = layer.thickness;

  GlazeLayer toLayer(int order) => GlazeLayer(
        layerOrder: order,
        recipeId: recipeId,
        revisionNum: revisionNum,
        recipeName: recipeName,
        coatCount: int.tryParse(coatCtrl.text.trim()),
        applicationMethod: applicationMethod,
        thickness: thickness,
      );

  void dispose() => coatCtrl.dispose();
}

// ── Layer editor card ─────────────────────────────────────────────────────────

class _LayerEditorCard extends StatelessWidget {
  const _LayerEditorCard({
    super.key,
    required this.layerNum,
    required this.state,
    required this.onChanged,
    required this.onRemove,
    required this.onPickRecipe,
  });

  final int layerNum;
  final _LayerState state;
  final VoidCallback onChanged;
  final VoidCallback onRemove;
  final VoidCallback onPickRecipe;

  static const _applicationMethods = ['Brush', 'Dip', 'Spray', 'Pour', 'Other'];
  static const _thicknesses = ['Thin', 'Medium', 'Thick'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasRecipe = state.recipeId != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
            // Recipe selector
            InkWell(
              onTap: onPickRecipe,
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: hasRecipe
                        ? scheme.primary.withValues(alpha: 0.5)
                        : scheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.science_outlined,
                      size: 16,
                      color: hasRecipe ? scheme.primary : scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.recipeName ?? 'Select a glaze recipe',
                        style: TextStyle(
                          color: hasRecipe
                              ? scheme.onSurface
                              : scheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      hasRecipe ? Icons.edit_outlined : Icons.chevron_right,
                      size: hasRecipe ? 14 : 18,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Builder(builder: (context) {
                  final coats = int.tryParse(state.coatCtrl.text) ?? 1;
                  return SizedBox(
                    width: 100,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Coats',
                        isDense: true,
                        border: OutlineInputBorder(),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: coats > 1
                                ? () {
                                    state.coatCtrl.text = '${coats - 1}';
                                    onChanged();
                                  }
                                : null,
                            child: Icon(Icons.remove, size: 16,
                                color: coats > 1
                                    ? null
                                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                          ),
                          Text('$coats',
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500)),
                          GestureDetector(
                            onTap: coats < 20
                                ? () {
                                    state.coatCtrl.text = '${coats + 1}';
                                    onChanged();
                                  }
                                : null,
                            child: Icon(Icons.add, size: 16,
                                color: coats < 20
                                    ? null
                                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
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

// ── Recipe picker sheet ───────────────────────────────────────────────────────

class _RecipePickerSheet extends ConsumerStatefulWidget {
  const _RecipePickerSheet();

  @override
  ConsumerState<_RecipePickerSheet> createState() => _RecipePickerSheetState();
}

class _RecipePickerSheetState extends ConsumerState<_RecipePickerSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipesAsync = ref.watch(recipesListProvider);
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text('Select Glaze Recipe',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search recipes...',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
            ),
          ),
          SizedBox(
            height: 300,
            child: recipesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Failed to load recipes',
                      style: TextStyle(color: scheme.error)),
                ),
              ),
              data: (recipes) {
                final filtered = _query.isEmpty
                    ? recipes
                    : recipes
                        .where((r) => r.name.toLowerCase().contains(_query))
                        .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      _query.isEmpty
                          ? 'No recipes yet.'
                          : 'No results for "$_query"',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final r = filtered[i];
                    final meta = [
                      if (r.cone.isNotEmpty) 'Cone ${r.cone}',
                      if (r.firingType.isNotEmpty) r.firingType,
                    ].join(' · ');
                    return ListTile(
                      leading: const Icon(Icons.science_outlined),
                      title: Text(r.name),
                      subtitle: meta.isNotEmpty ? Text(meta) : null,
                      trailing: r.revisionCount > 1
                          ? Text('v${r.revisionCount}',
                              style: Theme.of(context).textTheme.bodySmall)
                          : null,
                      dense: true,
                      onTap: () => Navigator.of(context).pop(r),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
