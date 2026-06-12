import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/chemistry/umf_calculator.dart';
import '../../core/materials/materials_repository.dart';
import '../../core/settings/settings_provider.dart';
import 'recipe_models.dart';
import 'recipes_repository.dart';

// Common materials pinned at the top of the picker (in order)
const _pinnedMaterialNames = [
  'Silica',
  'Flint',
  'Custer Feldspar',
  'Potash Feldspar',
  'G-200 Feldspar',
  'EPK Kaolin',
  'Kaolin',
  'Whiting',
  'Dolomite',
  'Talc',
  'Zinc Oxide',
  'Nepheline Syenite',
  'Gerstley Borate',
  'Ferro Frit 3134',
  'Ferro Frit 3124',
  'Ferro Frit 3195',
  'Wollastonite',
  'Alumina Hydrate',
  'Spodumene',
  'Barium Carbonate',
  'Lithium Carbonate',
  'Rutile',
  'Titanium Dioxide',
  'Strontium Carbonate',
  'Magnesium Carbonate',
  'Colemanite',
];
final _pinnedSet = _pinnedMaterialNames.toSet();

const _cones = [
  '022','021','020','019','018','017','016','015','014','013',
  '012','011','010','09','08','07','06','05','04','03','02','01',
  '1','2','3','4','5','6','7','8','9','10','11','12','13','14',
];
const _firingTypes = [
  'Oxidation', 'Reduction', 'Neutral', 'Soda', 'Wood', 'Salt',
];
const _colorOptions = [
  'Clear', 'White', 'Cream', 'Yellow', 'Orange', 'Red',
  'Pink', 'Purple', 'Blue', 'Teal', 'Green', 'Brown', 'Black', 'Gray',
];
const _finishOptions  = ['Glossy', 'Satin', 'Matte', 'Velvety', 'Dry'];
const _surfaceOptions = ['Smooth', 'Textured', 'Speckled', 'Crawled', 'Crystalline', 'Variegated'];
const _transparencyOptions = ['Transparent', 'Translucent', 'Semi-opaque', 'Opaque'];

// Status configuration
const _statuses = ['New', 'Testing', 'Tested'];
Color _statusColor(String status, ColorScheme cs) => switch (status) {
      'Testing' => Colors.orange,
      'Tested'  => Colors.green,
      _         => cs.outline,
    };

class RecipeEditorScreen extends ConsumerStatefulWidget {
  const RecipeEditorScreen({super.key, this.existing});
  final RecipeDetail? existing;

  @override
  ConsumerState<RecipeEditorScreen> createState() => _RecipeEditorScreenState();
}

class _RecipeEditorScreenState extends ConsumerState<RecipeEditorScreen> {
  final _nameCtrl  = TextEditingController();
  final _descCtrl  = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _cone;
  String? _firingType;
  final List<String> _colors = [];
  String? _finish;
  String? _surface;
  String? _transparency;
  bool _isPublic      = false;
  bool _saving        = false;
  bool _aiLoading     = false;
  bool _uploadingImage = false;
  bool _showAdditions = false;

  String _status = 'New';
  final List<String> _imageUrls = [];
  final List<_IngredientState> _baseIngredients     = [];
  final List<_IngredientState> _additionIngredients = [];

  bool get _isEdit => widget.existing != null;

  // Kept for future UI differentiation between latest/older revision editing
  // (see CLAUDE.md — both branches currently route to updateRevision).
  // ignore: unused_element
  bool get _isEditingLatest {
    if (!_isEdit) return true;
    final rev = widget.existing!.revision;
    if (rev == null) return true;
    return rev.revisionNum >= widget.existing!.revisionCount;
  }

  double get _totalPct =>
      _baseIngredients.fold(0.0, (s, i) => s + i.percentage);
  double get _additionsPct =>
      _additionIngredients.fold(0.0, (s, i) => s + i.percentage);

  List<RecipeIngredient> get _baseRecipeIngredients => _baseIngredients
      .where((s) => s.name.isNotEmpty && s.percentage > 0)
      .map((s) => RecipeIngredient(name: s.name, percentage: s.percentage))
      .toList();

  List<RecipeIngredient> get _builtIngredients => [
        ..._baseIngredients
            .where((s) => s.name.isNotEmpty)
            .map((s) => RecipeIngredient(name: s.name, percentage: s.percentage)),
        if (_showAdditions)
          ..._additionIngredients
              .where((s) => s.name.isNotEmpty)
              .map((s) => RecipeIngredient(
                  name: s.name, percentage: s.percentage, isAddition: true)),
      ];

  @override
  void initState() {
    super.initState();
    ref.read(materialsProvider.future).ignore();

    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text  = e.name;
      _descCtrl.text  = e.description;
      final revNotes = e.revision?.notes ?? '';
      _notesCtrl.text = revNotes.isNotEmpty ? revNotes : e.notes;
      _cone         = e.cone.isEmpty ? null : e.cone;
      _firingType   = e.firingType.isEmpty ? null : e.firingType;
      _colors.addAll(e.color);
      _finish       = e.finish.isEmpty ? null : e.finish;
      _surface      = e.surface.isEmpty ? null : e.surface;
      _transparency = e.transparency.isEmpty ? null : e.transparency;
      _isPublic     = e.isPublic;
      _status       = e.revision?.status ?? e.status;
      _imageUrls.addAll(e.revision?.imageUrls ?? []);
      for (final m in e.revision?.materials ?? []) {
        final s = _IngredientState.fromIngredient(m);
        if (m.isAddition) {
          _additionIngredients.add(s);
        } else {
          _baseIngredients.add(s);
        }
      }
      if (_additionIngredients.isNotEmpty) _showAdditions = true;
    } else {
      // Read defaults from settings
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final settings = ref.read(settingsNotifierProvider);
        setState(() {
          _cone       = settings.defaultCone;
          _firingType = settings.defaultFiringType;
        });
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _notesCtrl.dispose();
    for (final s in _baseIngredients)     s.dispose();
    for (final s in _additionIngredients) s.dispose();
    super.dispose();
  }

  // ── AI generate ─────────────────────────────────────────────────────────────

  Future<void> _generateAi() async {
    final name = _nameCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    if (name.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Enter both a name and description for best results')));
      return;
    }
    final prompt = '$name $desc'.trim();
    setState(() => _aiLoading = true);
    try {
      final generated = await ref
          .read(recipesRepositoryProvider)
          .generateAiRecipe(
            description: prompt,
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
        if (_additionIngredients.isNotEmpty) _showAdditions = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), duration: const Duration(seconds: 4)));
      }
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  // ── Photo picker ─────────────────────────────────────────────────────────────

  void _setImagePrimary(int index) {
    if (index == 0) return;
    setState(() {
      final url = _imageUrls.removeAt(index);
      _imageUrls.insert(0, url);
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_imageUrls.length >= 5) return;
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: source, imageQuality: 80);
    if (xfile == null || !mounted) return;
    setState(() => _uploadingImage = true);
    try {
      final bytes = await xfile.readAsBytes();
      final url = await ref
          .read(recipesRepositoryProvider)
          .uploadImage(bytes, 'image/jpeg');
      if (mounted) setState(() => _imageUrls.add(url));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Photo library'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Ingredient picker ─────────────────────────────────────────────────────────

  Future<void> _showPicker({required bool isAddition}) async {
    final result = await showModalBottomSheet<_PickerResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => const _MaterialPickerSheet(),
    );
    if (result == null || !mounted) return;
    setState(() {
      final s = _IngredientState(
          name: result.name, pct: result.percentage.toStringAsFixed(1));
      if (isAddition) {
        _additionIngredients.add(s);
      } else {
        _baseIngredients.add(s);
      }
    });
  }

  void _promoteToBase(int index) {
    setState(() {
      final s = _additionIngredients.removeAt(index);
      _baseIngredients.add(s);
      if (_additionIngredients.isEmpty) _showAdditions = false;
    });
  }

  // ── Save ─────────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }

    // Warn if base total is less than 100%
    if (_totalPct < 99.5 && _baseIngredients.isNotEmpty) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Recipe total is under 100%'),
          content: Text(
              'Base ingredients total ${_totalPct.toStringAsFixed(1)}%. '
              'Most glazes should total 100%. Save anyway?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Keep editing')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save anyway')),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }

    // Warn if additions are hidden but non-empty
    if (!_showAdditions && _additionIngredients.isNotEmpty) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Additions are hidden'),
          content: const Text(
              'The additions section is off — those ingredients will not be saved. Continue?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save without additions')),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }

    setState(() => _saving = true);
    try {
      final repo      = ref.read(recipesRepositoryProvider);
      final materials = _builtIngredients;
      final desc  = _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim();
      final notes = _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();
      if (_isEdit) {
        final id     = widget.existing!.id;
        final revNum = widget.existing!.revision?.revisionNum
            ?? widget.existing!.revisionCount;
        await repo.updateRevision(id, revNum,
            name: name, description: desc, cone: _cone,
            firingType: _firingType, notes: notes, isPublic: _isPublic,
            color: _colors, finish: _finish, surface: _surface,
            transparency: _transparency,
            materials: materials, imageUrls: _imageUrls, status: _status);
        ref.invalidate(recipeDetailProvider(id));
        ref.invalidate(recipeRevisionsProvider(id));
        ref.invalidate(recipesListProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Saved!'), duration: Duration(seconds: 2)));
        }
      } else {
        final id = await repo.createRecipe(
          name: name, description: desc, cone: _cone,
          firingType: _firingType, notes: notes, isPublic: _isPublic,
          color: _colors, finish: _finish, surface: _surface,
          transparency: _transparency,
          materials: materials, imageUrls: _imageUrls, status: _status,
        );
        ref.invalidate(recipesListProvider);
        if (!mounted) return;
        final detail = await repo.getRecipe(id);
        if (mounted) context.pushReplacement('/recipe/$id/edit', extra: detail);
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

  Future<void> _saveAsNewRevision() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Revision?'),
        content: const Text(
            'This creates a new version and preserves the current one in history.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Create Revision')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      final repo  = ref.read(recipesRepositoryProvider);
      final id    = widget.existing!.id;
      final desc  = _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim();
      final notes = _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();
      await repo.createRevision(id,
          name: name, description: desc, cone: _cone,
          firingType: _firingType, notes: notes, isPublic: _isPublic,
          color: _colors, finish: _finish, surface: _surface,
          transparency: _transparency,
          materials: _builtIngredients, imageUrls: _imageUrls, status: _status);
      ref.invalidate(recipeDetailProvider(id));
      ref.invalidate(recipeRevisionsProvider(id));
      ref.invalidate(recipesListProvider);
      if (!mounted) return;
      final detail = await repo.getRecipe(id);
      if (mounted) context.pushReplacement('/recipe/$id/edit', extra: detail);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final totalPct = _totalPct;
    final over     = totalPct > 100.5;
    final scheme   = Theme.of(context).colorScheme;
    final pctColor = over
        ? scheme.error
        : (totalPct - 100).abs() < 0.5
            ? Colors.green
            : Colors.orange;

    return Scaffold(
      appBar: AppBar(
        titleTextStyle: Theme.of(context).textTheme.titleMedium,
        title: Text(_isEdit
            ? 'Edit Recipe${widget.existing?.revision != null ? " · v${widget.existing!.revision!.revisionNum}" : ""}'
            : 'New Recipe'),
        actions: [
          if (_aiLoading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            IconButton(
              tooltip: 'Generate with AI',
              icon: const Icon(Icons.auto_awesome_outlined),
              onPressed: _generateAi,
            ),
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else ...[
            if (_isEdit)
              IconButton(
                icon: const Icon(Icons.fork_right_outlined),
                tooltip: 'Create new revision',
                onPressed: _saveAsNewRevision,
              ),
            TextButton(onPressed: _save, child: const Text('Save')),
          ],
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          // ── Basic info ─────────────────────────────────────────────────────
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
                initialValue: _cones.contains(_cone) ? _cone : null,
                hint: const Text('Cone'),
                decoration:
                    const InputDecoration(border: OutlineInputBorder()),
                items: _cones
                    .map((c) => DropdownMenuItem(
                        value: c,
                        child: Row(children: [
                          const Icon(Icons.change_history, size: 14),
                          const SizedBox(width: 4),
                          Text(c),
                        ])))
                    .toList(),
                onChanged: (v) => setState(() => _cone = v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _firingTypes.contains(_firingType) ? _firingType : null,
                hint: const Text('Firing type'),
                decoration:
                    const InputDecoration(border: OutlineInputBorder()),
                items: _firingTypes
                    .map((f) =>
                        DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (v) => setState(() => _firingType = v),
              ),
            ),
          ]),
          const SizedBox(height: 12),

          // Status
          Row(children: [
            Text('Status', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(width: 12),
            ..._statuses.map((s) {
              final selected = _status == s;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(s),
                  selected: selected,
                  selectedColor: _statusColor(s, scheme).withAlpha(60),
                  side: BorderSide(
                      color: selected
                          ? _statusColor(s, scheme)
                          : scheme.outlineVariant),
                  onSelected: (_) => setState(() => _status = s),
                ),
              );
            }),
          ]),
          const SizedBox(height: 8),

          SwitchListTile(
            title: const Text('Share publicly'),
            subtitle: const Text('Visible to the community'),
            value: _isPublic,
            onChanged: (v) => setState(() => _isPublic = v),
            contentPadding: EdgeInsets.zero,
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // ── Glaze attributes ───────────────────────────────────────────────
          InkWell(
            onTap: () async {
              final result = await showDialog<List<String>>(
                context: context,
                builder: (_) => _ColorPickerDialog(initial: _colors),
              );
              if (result != null) setState(() { _colors
                ..clear()
                ..addAll(result); });
            },
            borderRadius: BorderRadius.circular(4),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Color',
                border: OutlineInputBorder(),
                isDense: true,
                suffixIcon: Icon(Icons.arrow_drop_down),
              ),
              child: Text(
                _colors.isEmpty ? 'None' : _colors.join(', '),
                style: _colors.isEmpty
                    ? TextStyle(color: scheme.onSurfaceVariant)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final result = await showDialog<({String? finish, String? surface, String? transparency})>(
                context: context,
                builder: (_) => _GlazeAttrsDialog(
                    finish: _finish, surface: _surface, transparency: _transparency),
              );
              if (result != null) setState(() {
                _finish       = result.finish;
                _surface      = result.surface;
                _transparency = result.transparency;
              });
            },
            borderRadius: BorderRadius.circular(4),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Finish / Surface / Transparency',
                border: OutlineInputBorder(),
                isDense: true,
                suffixIcon: Icon(Icons.arrow_drop_down),
              ),
              child: Builder(builder: (context) {
                final parts = [
                  if (_finish != null) _finish!,
                  if (_surface != null) _surface!,
                  if (_transparency != null) _transparency!,
                ];
                return Text(
                  parts.isEmpty ? 'None' : parts.join(' · '),
                  style: parts.isEmpty
                      ? TextStyle(color: scheme.onSurfaceVariant)
                      : null,
                );
              }),
            ),
          ),

          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 12),

          // ── Photos ────────────────────────────────────────────────────────
          _PhotoSection(
            urls: _imageUrls,
            uploading: _uploadingImage,
            onAdd: _imageUrls.length < 5 ? _showImageSourceSheet : null,
            onRemove: (i) => setState(() => _imageUrls.removeAt(i)),
            onSetPrimary: _setImagePrimary,
          ),

          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 12),

          // ── Base ingredients ───────────────────────────────────────────────
          Row(children: [
            Text('Ingredients',
                style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            if (over)
              Tooltip(
                message: 'Total exceeds 100%',
                child: Icon(Icons.warning_amber_rounded,
                    size: 18, color: scheme.error),
              ),
            const SizedBox(width: 4),
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
              onReorderItem: (oldIndex, newIndex) {
                setState(() {
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

          // ── Additions ──────────────────────────────────────────────────────
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: Divider(color: scheme.outlineVariant)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                _showAdditions && _additionIngredients.isNotEmpty
                    ? 'Additions  ${_additionsPct.toStringAsFixed(1)}%'
                    : 'Additions',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant),
              ),
            ),
            Expanded(child: Divider(color: scheme.outlineVariant)),
            IconButton(
              icon: Icon(
                  _showAdditions ? Icons.expand_less : Icons.expand_more,
                  size: 20),
              tooltip: _showAdditions ? 'Hide additions' : 'Show additions',
              onPressed: () =>
                  setState(() => _showAdditions = !_showAdditions),
              visualDensity: VisualDensity.compact,
            ),
            if (_showAdditions)
              TextButton.icon(
                onPressed: () => _showPicker(isAddition: true),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
          ]),
          if (_showAdditions && _additionIngredients.isNotEmpty)
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: _additionIngredients.length,
              onReorderItem: (oldIndex, newIndex) {
                setState(() {
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
                  onPromote: () => _promoteToBase(index),
                );
              },
            ),
          if (_showAdditions && _additionIngredients.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('No additions yet.',
                  style: TextStyle(color: Colors.grey.shade500)),
            ),

          // ── UMF preview ────────────────────────────────────────────────────
          if (_baseRecipeIngredients.isNotEmpty) ...[
            const SizedBox(height: 16),
            _UmfPreviewStrip(ingredients: _baseRecipeIngredients),
          ],

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
}

// ── Photo section ─────────────────────────────────────────────────────────────

class _PhotoSection extends StatelessWidget {
  const _PhotoSection({
    required this.urls,
    required this.uploading,
    required this.onAdd,
    required this.onRemove,
    required this.onSetPrimary,
  });
  final List<String> urls;
  final bool uploading;
  final VoidCallback? onAdd;
  final void Function(int index) onRemove;
  final void Function(int index) onSetPrimary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('Photos', style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          if (uploading)
            const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2))
          else if (onAdd != null)
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_a_photo_outlined, size: 18),
              label: Text('Add (${urls.length}/5)'),
            )
          else
            Text('5/5',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        ]),
        if (urls.isNotEmpty)
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: urls.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(urls[i],
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                            width: 90,
                            height: 90,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.broken_image_outlined))),
                  ),
                  // Remove button
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () => onRemove(i),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(2),
                        child: const Icon(Icons.close,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                  // Primary badge / set-primary button
                  Positioned(
                    bottom: 2,
                    left: 2,
                    child: GestureDetector(
                      onTap: i == 0 ? null : () => onSetPrimary(i),
                      child: Container(
                        decoration: BoxDecoration(
                          color: i == 0
                              ? Colors.amber.withAlpha(200)
                              : Colors.black45,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(3),
                        child: Icon(
                          i == 0 ? Icons.star : Icons.star_border,
                          size: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
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
    this.onPromote,
  });
  final int index;
  final _IngredientState state;
  final VoidCallback onRemove;
  final VoidCallback onChanged;
  final VoidCallback? onPromote;

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
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                LengthLimitingTextInputFormatter(6),
              ],
              onTap: () => state.pctCtrl.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: state.pctCtrl.text.length),
              onChanged: (_) => onChanged(),
            ),
          ),
          if (onPromote != null)
            IconButton(
              icon: const Icon(Icons.arrow_upward, size: 18),
              tooltip: 'Move to base',
              onPressed: onPromote,
              visualDensity: VisualDensity.compact,
              color: Colors.grey,
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
    if (pct > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Percentage cannot exceed 100%')),
      );
      return;
    }
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
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text('Add Ingredient',
                style: Theme.of(context).textTheme.titleMedium),
          ),
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
          SizedBox(
            height: 280,
            child: materialsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ManualEntryFallback(
                onChanged: (name) => setState(() => _selected = name),
              ),
              data: (materials) {
                // Sort: pinned first (in order), then alphabetical
                final pinned = <dynamic>[];
                for (final name in _pinnedMaterialNames) {
                  final found = materials.where((m) => m.name == name).firstOrNull;
                  if (found != null) pinned.add(found);
                }
                final rest = materials
                    .where((m) => !_pinnedSet.contains(m.name))
                    .toList()
                  ..sort((a, b) => a.name.compareTo(b.name));
                final sorted = [...pinned, ...rest];

                final filtered = _query.isEmpty
                    ? sorted
                    : sorted
                        .where((m) =>
                            m.name.toLowerCase().contains(_query))
                        .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text('No results for "$_query"',
                        style:
                            TextStyle(color: scheme.onSurfaceVariant)),
                  );
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final m = filtered[i];
                    final isSelected = _selected == m.name;
                    final isPinned   = _pinnedSet.contains(m.name);
                    return ListTile(
                      title: Text(m.name),
                      subtitle: m.description.isNotEmpty
                          ? Text(m.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis)
                          : null,
                      selected: isSelected,
                      selectedTileColor:
                          scheme.primaryContainer.withAlpha(80),
                      leading: isPinned && _query.isEmpty
                          ? Icon(Icons.star_outline,
                              size: 14,
                              color: scheme.primary.withAlpha(160))
                          : null,
                      trailing: m.hazardous
                          ? Tooltip(
                              message: 'Hazardous material',
                              child: Icon(Icons.warning_amber_outlined,
                                  size: 16, color: scheme.error))
                          : null,
                      dense: true,
                      onTap: () {
                        setState(() => _selected = m.name);
                        FocusScope.of(context).nextFocus();
                      },
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: _selected != null
                      ? Text(_selected!,
                          style:
                              const TextStyle(fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis)
                      : Text('Select a material above',
                          style:
                              TextStyle(color: scheme.onSurfaceVariant)),
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
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      LengthLimitingTextInputFormatter(6),
                    ],
                    onTap: () => _amountCtrl.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: _amountCtrl.text.length),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _confirm(),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _selected != null &&
                          (double.tryParse(_amountCtrl.text) ?? 0) > 0 &&
                          (double.tryParse(_amountCtrl.text) ?? 0) <= 100
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

// ── UMF preview strip ─────────────────────────────────────────────────────────

class _UmfPreviewStrip extends ConsumerStatefulWidget {
  const _UmfPreviewStrip({required this.ingredients});
  final List<RecipeIngredient> ingredients;

  @override
  ConsumerState<_UmfPreviewStrip> createState() => _UmfPreviewStripState();
}

class _UmfPreviewStripState extends ConsumerState<_UmfPreviewStrip> {
  bool _showSuggestions = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final materialsAsync = ref.watch(materialsProvider);

    return materialsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (materials) {
        final umf = calculateUmf(widget.ingredients, materials);
        if (umf == null) return const SizedBox.shrink();

        final zone = umfZone(umf);
        final suggestions = glazeSuggestions(umf);

        final (zoneLabel, zoneColor) = switch (zone) {
          GlazeZone.underfired => ('Underfired', Colors.red),
          GlazeZone.running    => ('Running',    Colors.blue),
          GlazeZone.matte      => ('Matte',      Colors.orange),
          GlazeZone.glossy     => ('Glossy',     Colors.green),
        };

        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text('UMF Preview',
                      style: Theme.of(context).textTheme.titleSmall),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: zoneColor.withAlpha(40),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: zoneColor.withAlpha(120)),
                    ),
                    child: Text(zoneLabel,
                        style: TextStyle(fontSize: 12, color: zoneColor)),
                  ),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  _UmfValue('Si', umf.si),
                  const SizedBox(width: 20),
                  _UmfValue('Al', umf.al),
                  if (umf.b > 0) ...[
                    const SizedBox(width: 20),
                    _UmfValue('B', umf.b),
                  ],
                  const Spacer(),
                  Text('Si:Al ${umf.siAl.toStringAsFixed(1)}',
                      style: Theme.of(context).textTheme.bodySmall),
                ]),
                if (suggestions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(4),
                    onTap: () =>
                        setState(() => _showSuggestions = !_showSuggestions),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(children: [
                        Icon(Icons.tips_and_updates_outlined,
                            size: 14, color: Colors.amber.shade700),
                        const SizedBox(width: 4),
                        Text(
                          '${suggestions.length} suggestion${suggestions.length == 1 ? '' : 's'}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.amber.shade700),
                        ),
                        const Spacer(),
                        Icon(
                            _showSuggestions
                                ? Icons.expand_less
                                : Icons.expand_more,
                            size: 16,
                            color: scheme.onSurfaceVariant),
                      ]),
                    ),
                  ),
                  if (_showSuggestions) ...[
                    const SizedBox(height: 8),
                    ...suggestions.map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                s.isWarning
                                    ? Icons.warning_amber_outlined
                                    : Icons.arrow_right,
                                size: 16,
                                color: s.isWarning
                                    ? scheme.error
                                    : scheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.message,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500)),
                                    if (s.detail.isNotEmpty)
                                      Text(s.detail,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color:
                                                  scheme.onSurfaceVariant)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _UmfValue extends StatelessWidget {
  const _UmfValue(this.label, this.value);
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(value.toStringAsFixed(2),
            style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

// ── Manual entry fallback ─────────────────────────────────────────────────────

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

// ── Glaze attributes dialog (finish / surface / transparency) ─────────────────

class _GlazeAttrsDialog extends StatefulWidget {
  const _GlazeAttrsDialog({this.finish, this.surface, this.transparency});
  final String? finish;
  final String? surface;
  final String? transparency;

  @override
  State<_GlazeAttrsDialog> createState() => _GlazeAttrsDialogState();
}

class _GlazeAttrsDialogState extends State<_GlazeAttrsDialog> {
  String? _finish;
  String? _surface;
  String? _transparency;

  @override
  void initState() {
    super.initState();
    _finish       = widget.finish;
    _surface      = widget.surface;
    _transparency = widget.transparency;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Glaze Properties'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _finishOptions.contains(_finish) ? _finish : null,
            hint: const Text('Finish'),
            decoration: const InputDecoration(
                labelText: 'Finish', border: OutlineInputBorder(), isDense: true),
            items: [
              const DropdownMenuItem(value: null, child: Text('—')),
              ..._finishOptions.map((f) => DropdownMenuItem(value: f, child: Text(f))),
            ],
            onChanged: (v) => setState(() => _finish = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _surfaceOptions.contains(_surface) ? _surface : null,
            hint: const Text('Surface'),
            decoration: const InputDecoration(
                labelText: 'Surface', border: OutlineInputBorder(), isDense: true),
            items: [
              const DropdownMenuItem(value: null, child: Text('—')),
              ..._surfaceOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))),
            ],
            onChanged: (v) => setState(() => _surface = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _transparencyOptions.contains(_transparency) ? _transparency : null,
            hint: const Text('Transparency'),
            decoration: const InputDecoration(
                labelText: 'Transparency', border: OutlineInputBorder(), isDense: true),
            items: [
              const DropdownMenuItem(value: null, child: Text('—')),
              ..._transparencyOptions.map((t) => DropdownMenuItem(value: t, child: Text(t))),
            ],
            onChanged: (v) => setState(() => _transparency = v),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.pop(
                context,
                (finish: _finish, surface: _surface, transparency: _transparency)),
            child: const Text('Done')),
      ],
    );
  }
}

// ── Color picker dialog ───────────────────────────────────────────────────────

class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({required this.initial});
  final List<String> initial;

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late final List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List<String>.from(widget.initial);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Color'),
      content: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: _colorOptions.map((c) {
          final sel = _selected.contains(c);
          return FilterChip(
            label: Text(c),
            selected: sel,
            visualDensity: VisualDensity.compact,
            onSelected: (_) => setState(() {
              if (sel) _selected.remove(c); else _selected.add(c);
            }),
          );
        }).toList(),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.pop(context, _selected),
            child: const Text('Done')),
      ],
    );
  }
}
