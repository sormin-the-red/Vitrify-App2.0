import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/materials/materials_repository.dart';
import 'recipe_models.dart';
import 'recipes_repository.dart';

class RecipeEditorScreen extends ConsumerStatefulWidget {
  const RecipeEditorScreen({super.key, this.existing});
  final RecipeDetail? existing;

  @override
  ConsumerState<RecipeEditorScreen> createState() => _RecipeEditorScreenState();
}

class _RecipeEditorScreenState extends ConsumerState<RecipeEditorScreen> {
  static const _cones = [
    '022','021','020','019','018','017','016','015','014','013',
    '012','011','010','09','08','07','06','05','04','03','02','01',
    '1','2','3','4','5','6','7','8','9','10','11','12','13','14',
  ];
  static const _firingTypes = [
    'Oxidation', 'Reduction', 'Neutral', 'Soda', 'Wood', 'Salt',
  ];

  final _nameCtrl    = TextEditingController();
  final _descCtrl    = TextEditingController();
  final _notesCtrl   = TextEditingController();
  final _aiDescCtrl  = TextEditingController();

  String? _cone;
  String? _firingType;
  bool _isPublic  = false;
  bool _saving    = false;
  bool _aiLoading = false;

  final List<_IngredientState> _baseIngredients     = [];
  final List<_IngredientState> _additionIngredients = [];

  bool get _isEdit => widget.existing != null;

  double get _totalPct =>
      _baseIngredients.fold(0.0, (s, i) => s + i.percentage);
  double get _additionsPct =>
      _additionIngredients.fold(0.0, (s, i) => s + i.percentage);

  List<RecipeIngredient> get _builtIngredients => [
        ..._baseIngredients
            .where((s) => s.name.isNotEmpty)
            .map((s) => RecipeIngredient(name: s.name, percentage: s.percentage)),
        ..._additionIngredients
            .where((s) => s.name.isNotEmpty)
            .map((s) =>
                RecipeIngredient(name: s.name, percentage: s.percentage, isAddition: true)),
      ];

  @override
  void initState() {
    super.initState();
    // Kick off materials load so it's ready when the picker opens.
    ref.read(materialsProvider.future).ignore();

    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text  = e.name;
      _descCtrl.text  = e.description;
      _notesCtrl.text = e.notes;
      _cone       = e.cone.isEmpty ? null : e.cone;
      _firingType = e.firingType.isEmpty ? null : e.firingType;
      _isPublic   = e.isPublic;
      for (final m in e.revision?.materials ?? []) {
        final s = _IngredientState.fromIngredient(m);
        if (m.isAddition) {
          _additionIngredients.add(s);
        } else {
          _baseIngredients.add(s);
        }
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _notesCtrl.dispose();
    _aiDescCtrl.dispose();
    for (final s in _baseIngredients)     s.dispose();
    for (final s in _additionIngredients) s.dispose();
    super.dispose();
  }

  Future<void> _showPicker({required bool isAddition}) async {
    final result = await showModalBottomSheet<_PickerResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _MaterialPickerSheet(),
    );
    if (result == null || !mounted) return;
    setState(() {
      final s = _IngredientState(
        name: result.name,
        pct: result.percentage.toStringAsFixed(1),
      );
      if (isAddition) {
        _additionIngredients.add(s);
      } else {
        _baseIngredients.add(s);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalPct = _totalPct;
    final pctColor =
        (totalPct - 100).abs() < 0.5 ? Colors.green : Colors.orange;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Recipe' : 'New Recipe'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          // ── Basic info ────────────────────────────────────────────────────
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
                labelText: 'Name *', border: OutlineInputBorder()),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(
                labelText: 'Description', border: OutlineInputBorder()),
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _cone,
                hint: const Text('Cone'),
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: _cones
                    .map((c) =>
                        DropdownMenuItem(value: c, child: Text('Cone $c')))
                    .toList(),
                onChanged: (v) => setState(() => _cone = v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _firingType,
                hint: const Text('Firing type'),
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: _firingTypes
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (v) => setState(() => _firingType = v),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Share publicly'),
            subtitle: const Text('Visible to the community'),
            value: _isPublic,
            onChanged: (v) => setState(() => _isPublic = v),
            contentPadding: EdgeInsets.zero,
          ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),

          // ── AI generate ───────────────────────────────────────────────────
          Text('AI Recipe Generator',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _aiDescCtrl,
                decoration: const InputDecoration(
                  hintText: 'Describe the glaze you want...',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: _aiLoading ? null : _generateAi,
              child: _aiLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Generate'),
            ),
          ]),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),

          // ── Base ingredients ──────────────────────────────────────────────
          Row(children: [
            Text('Ingredients',
                style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            Text(
              '${totalPct.toStringAsFixed(1)}%',
              style: TextStyle(color: pctColor, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () => _showPicker(isAddition: false),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ]),
          if (_baseIngredients.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('No ingredients yet.',
                  style: TextStyle(color: Colors.grey.shade500)),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: _baseIngredients.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _baseIngredients.removeAt(oldIndex);
                  _baseIngredients.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final s = _baseIngredients[index];
                return _IngredientRow(
                  key: s.key,
                  index: index,
                  state: s,
                  onRemove: () =>
                      setState(() => _baseIngredients.removeAt(index)),
                  onChanged: () => setState(() {}),
                );
              },
            ),

          // ── Additions ─────────────────────────────────────────────────────
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: Divider(
                    color: Theme.of(context).colorScheme.outlineVariant)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                _additionIngredients.isEmpty
                    ? 'Additions'
                    : 'Additions  ${_additionsPct.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
            Expanded(
                child: Divider(
                    color: Theme.of(context).colorScheme.outlineVariant)),
            TextButton.icon(
              onPressed: () => _showPicker(isAddition: true),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ]),
          if (_additionIngredients.isNotEmpty)
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: _additionIngredients.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _additionIngredients.removeAt(oldIndex);
                  _additionIngredients.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final s = _additionIngredients[index];
                return _IngredientRow(
                  key: s.key,
                  index: index,
                  state: s,
                  onRemove: () =>
                      setState(() => _additionIngredients.removeAt(index)),
                  onChanged: () => setState(() {}),
                );
              },
            ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),

          // ── Notes ─────────────────────────────────────────────────────────
          TextField(
            controller: _notesCtrl,
            decoration: const InputDecoration(
                labelText: 'Notes', border: OutlineInputBorder()),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ),
    );
  }

  Future<void> _generateAi() async {
    final desc = _aiDescCtrl.text.trim();
    if (desc.isEmpty) return;
    setState(() => _aiLoading = true);
    try {
      final generated = await ref.read(recipesRepositoryProvider).generateAiRecipe(
            description: desc,
            cone: _cone,
            firingType: _firingType,
          );
      setState(() {
        for (final s in _baseIngredients)     s.dispose();
        for (final s in _additionIngredients) s.dispose();
        _baseIngredients.clear();
        _additionIngredients.clear();
        for (final m in generated) {
          final s = _IngredientState.fromIngredient(m);
          if (m.isAddition) {
            _additionIngredients.add(s);
          } else {
            _baseIngredients.add(s);
          }
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), duration: const Duration(seconds: 4)),
        );
      }
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }
    setState(() => _saving = true);
    try {
      final repo      = ref.read(recipesRepositoryProvider);
      final materials = _builtIngredients;
      if (_isEdit) {
        await repo.updateRecipe(
          widget.existing!.id,
          name: name,
          description:
              _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          cone: _cone,
          firingType: _firingType,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          isPublic: _isPublic,
          materials: materials,
        );
        ref.invalidate(recipeDetailProvider(widget.existing!.id));
        ref.invalidate(recipesListProvider);
        if (mounted) context.pop();
      } else {
        final id = await repo.createRecipe(
          name: name,
          description:
              _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          cone: _cone,
          firingType: _firingType,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          isPublic: _isPublic,
          materials: materials,
        );
        ref.invalidate(recipesListProvider);
        if (mounted) context.pushReplacement('/recipe/$id');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ── Picker result ─────────────────────────────────────────────────────────────

class _PickerResult {
  final String name;
  final double percentage;
  const _PickerResult(this.name, this.percentage);
}

// ── Ingredient state ──────────────────────────────────────────────────────────

class _IngredientState {
  final Key key = UniqueKey();
  String name;
  final TextEditingController pctCtrl;

  _IngredientState({this.name = '', String pct = ''})
      : pctCtrl = TextEditingController(text: pct);

  _IngredientState.fromIngredient(RecipeIngredient m)
      : name = m.name,
        pctCtrl = TextEditingController(
            text: m.percentage > 0 ? m.percentage.toStringAsFixed(1) : '');

  double get percentage => double.tryParse(pctCtrl.text) ?? 0;

  void dispose() => pctCtrl.dispose();
}

// ── Ingredient row ────────────────────────────────────────────────────────────

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    super.key,
    required this.index,
    required this.state,
    required this.onRemove,
    required this.onChanged,
  });
  final int index;
  final _IngredientState state;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.drag_handle, size: 20, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              state.name.isEmpty ? 'Unknown' : state.name,
              overflow: TextOverflow.ellipsis,
              style: state.name.isEmpty
                  ? const TextStyle(
                      color: Colors.grey, fontStyle: FontStyle.italic)
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 76,
            child: TextField(
              controller: state.pctCtrl,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                hintText: '0',
                suffixText: '%',
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onTap: () => state.pctCtrl.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: state.pctCtrl.text.length),
              onChanged: (_) => onChanged(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: onRemove,
            visualDensity: VisualDensity.compact,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }
}

// ── Material picker sheet ─────────────────────────────────────────────────────

class _MaterialPickerSheet extends ConsumerStatefulWidget {
  const _MaterialPickerSheet();

  @override
  ConsumerState<_MaterialPickerSheet> createState() =>
      _MaterialPickerSheetState();
}

class _MaterialPickerSheetState extends ConsumerState<_MaterialPickerSheet> {
  final _searchCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String? _selected;
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _confirm() {
    final pct = double.tryParse(_amountCtrl.text) ?? 0;
    if (_selected == null || pct <= 0) return;
    Navigator.of(context).pop(_PickerResult(_selected!, pct));
  }

  @override
  Widget build(BuildContext context) {
    final materialsAsync = ref.watch(materialsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
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
            child: Text('Add Ingredient',
                style: Theme.of(context).textTheme.titleMedium),
          ),

          // Search field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search materials...',
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

          // Materials list
          SizedBox(
            height: 280,
            child: materialsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ManualEntryFallback(
                onChanged: (name) => setState(() => _selected = name),
              ),
              data: (materials) {
                final filtered = _query.isEmpty
                    ? materials
                    : materials
                        .where((m) =>
                            m.name.toLowerCase().contains(_query))
                        .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No results for "$_query"',
                      style:
                          TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final m = filtered[i];
                    final isSelected = _selected == m.name;
                    return ListTile(
                      title: Text(m.name),
                      subtitle: m.description.isNotEmpty
                          ? Text(
                              m.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      selected: isSelected,
                      selectedTileColor:
                          scheme.primaryContainer.withAlpha(80),
                      trailing: m.hazardous
                          ? Tooltip(
                              message: 'Hazardous material',
                              child: Icon(
                                Icons.warning_amber_outlined,
                                size: 16,
                                color: scheme.error,
                              ),
                            )
                          : null,
                      dense: true,
                      onTap: () => setState(() {
                        _selected = m.name;
                        // Auto-focus amount field after selection
                        FocusScope.of(context).nextFocus();
                      }),
                    );
                  },
                );
              },
            ),
          ),

          const Divider(height: 1),

          // Bottom row: selected name + amount + Add
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: _selected != null
                      ? Text(
                          _selected!,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        )
                      : Text(
                          'Select a material above',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 84,
                  child: TextField(
                    controller: _amountCtrl,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      hintText: '0',
                      suffixText: '%',
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onTap: () => _amountCtrl.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: _amountCtrl.text.length),
                    onSubmitted: (_) => _confirm(),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _selected != null &&
                          (double.tryParse(_amountCtrl.text) ?? 0) > 0
                      ? _confirm
                      : null,
                  child: const Text('Add'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Manual entry fallback (when materials CDN is unreachable) ─────────────────

class _ManualEntryFallback extends StatefulWidget {
  const _ManualEntryFallback({required this.onChanged});
  final void Function(String name) onChanged;

  @override
  State<_ManualEntryFallback> createState() => _ManualEntryFallbackState();
}

class _ManualEntryFallbackState extends State<_ManualEntryFallback> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_outlined,
              size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'Could not load the materials database.\nEnter a name manually:',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            decoration: const InputDecoration(
              hintText: 'Material name',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: (v) => widget.onChanged(v.trim()),
          ),
        ],
      ),
    );
  }
}
