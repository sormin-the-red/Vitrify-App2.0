import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../recipes/recipe_models.dart';
import '../recipes/recipes_repository.dart';
import 'firing_chart.dart';
import 'schedule_models.dart';
import 'schedules_repository.dart';

class ScheduleEditorScreen extends ConsumerStatefulWidget {
  const ScheduleEditorScreen({super.key, this.existing});
  final ScheduleDetail? existing;

  @override
  ConsumerState<ScheduleEditorScreen> createState() =>
      _ScheduleEditorScreenState();
}

class _ScheduleEditorScreenState extends ConsumerState<ScheduleEditorScreen> {
  static const _cones = [
    '022','021','020','019','018','017','016','015','014','013',
    '012','011','010','09','08','07','06','05','04','03','02','01',
    '1','2','3','4','5','6','7','8','9','10','11','12','13','14'
  ];

  final _nameCtrl  = TextEditingController();
  final _descCtrl  = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _tempScale = 'F';
  String? _maxCone;
  bool _isPublic = false;
  final List<_SegmentState> _segments = [];
  final List<String> _linkedRecipeIds = [];
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text  = e.name;
      _descCtrl.text  = e.description;
      _notesCtrl.text = e.notes;
      _tempScale = e.tempScale.isEmpty ? 'F' : e.tempScale;
      _maxCone   = e.maxCone.isEmpty ? null : e.maxCone;
      _isPublic  = e.isPublic;
      for (final seg in e.revision?.segments ?? []) {
        _segments.add(_SegmentState.fromSegment(seg));
      }
      _linkedRecipeIds.addAll(e.revision?.linkedRecipeIds ?? []);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _notesCtrl.dispose();
    for (final s in _segments) {
      s.dispose();
    }
    super.dispose();
  }

  List<FiringSegment> get _builtSegments => _segments.map((s) => FiringSegment(
        lowTemp:     double.tryParse(s.lowCtrl.text),
        highTemp:    double.tryParse(s.highCtrl.text),
        ratePerHour: double.tryParse(s.rateCtrl.text),
        holdMinutes: double.tryParse(s.holdCtrl.text),
        note: s.noteCtrl.text.trim().isEmpty ? null : s.noteCtrl.text.trim(),
      )).toList();

  void _showSegmentModal({int? editIndex}) {
    final allSegs = _builtSegments;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SegmentModal(
        index: editIndex ?? _segments.length,
        allSegments: allSegs,
        scale: _tempScale,
        onConfirm: (seg) => setState(() {
          if (editIndex != null) {
            _segments[editIndex].dispose();
            _segments[editIndex] = _SegmentState.fromSegment(seg);
          } else {
            _segments.add(_SegmentState.fromSegment(seg));
          }
        }),
      ),
    );
  }

  // True when editing the latest revision (or creating new).
  bool get _isEditingLatest {
    if (!_isEdit) return true;
    final rev = widget.existing!.revision;
    if (rev == null) return true;
    return rev.revisionNum >= widget.existing!.revisionCount;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit
            ? 'Edit Schedule${widget.existing?.revision != null ? "  ·  v${widget.existing!.revision!.revisionNum}" : ""}'
            : 'New Schedule'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else ...[
            TextButton(onPressed: _save, child: const Text('Save')),
            if (_isEdit)
              PopupMenuButton<_EditorAction>(
                onSelected: (action) {
                  if (action == _EditorAction.newRevision) _saveAsNewRevision();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: _EditorAction.newRevision,
                    child: ListTile(
                      leading: Icon(Icons.fork_right_outlined),
                      title: Text('Save as New Revision'),
                      contentPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Name *',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Scale: '),
              const SizedBox(width: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'F', label: Text('°F')),
                  ButtonSegment(value: 'C', label: Text('°C')),
                ],
                selected: {_tempScale},
                onSelectionChanged: (s) =>
                    setState(() => _tempScale = s.first),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _maxCone,
                  hint: const Text('Max cone'),
                  decoration:
                      const InputDecoration(border: OutlineInputBorder()),
                  items: _cones
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text('Cone $c')))
                      .toList(),
                  onChanged: (v) => setState(() => _maxCone = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Share publicly'),
            value: _isPublic,
            onChanged: (v) => setState(() => _isPublic = v),
            contentPadding: EdgeInsets.zero,
          ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),

          // ── Segments ──────────────────────────────────────────────────────
          Row(
            children: [
              Text('Firing Segments',
                  style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              TextButton.icon(
                onPressed: _showSegmentModal,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          if (_segments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('No segments yet.',
                  style: TextStyle(color: Colors.grey.shade500)),
            )
          else
            Column(
              children: _segments.asMap().entries.map((entry) {
                final i = entry.key;
                final s = entry.value;
                return _SegmentTile(
                  key: s.key,
                  state: s,
                  index: i,
                  scale: _tempScale,
                  onEdit: () => _showSegmentModal(editIndex: i),
                  onRemove: () => setState(() {
                    s.dispose();
                    _segments.removeAt(i);
                  }),
                );
              }).toList(),
            ),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),

          // ── Linked recipes ─────────────────────────────────────────────────
          Row(
            children: [
              Text('Linked Recipes',
                  style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              TextButton.icon(
                onPressed: _pickLinkedRecipe,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Link'),
              ),
            ],
          ),
          if (_linkedRecipeIds.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('No linked recipes.',
                  style: TextStyle(color: Colors.grey.shade500)),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _linkedRecipeIds.map((id) {
                  return _LinkedRecipeChip(
                    recipeId: id,
                    onRemove: () =>
                        setState(() => _linkedRecipeIds.remove(id)),
                  );
                }).toList(),
              ),
            ),

          const Divider(),
          const SizedBox(height: 12),

          TextField(
            controller: _notesCtrl,
            decoration: const InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ),
    );
  }

  String? get _trimmedDesc =>
      _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim();
  String? get _trimmedNotes =>
      _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name is required')));
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(schedulesRepositoryProvider);
      if (_isEdit) {
        final id      = widget.existing!.id;
        final revNum  = widget.existing!.revision?.revisionNum
            ?? widget.existing!.revisionCount;
        final savedSegs = _builtSegments;

        await repo.updateRevision(id, revNum,
            name: name, description: _trimmedDesc, notes: _trimmedNotes,
            tempScale: _tempScale, maxCone: _maxCone, isPublic: _isPublic,
            segments: savedSegs,
            linkedRecipeIds: _linkedRecipeIds);
        ref.invalidate(scheduleDetailProvider(id));
        ref.invalidate(scheduleRevisionsProvider(id));
        ref.invalidate(schedulesListProvider);
        if (mounted) {
          context.pop(ScheduleRevision(
            revisionNum: revNum,
            segments: savedSegs,
            linkedRecipeIds: List<String>.from(_linkedRecipeIds),
            dateCreated: widget.existing!.revision?.dateCreated ?? '',
          ));
        }
      } else {
        final id = await repo.createSchedule(
          name: name, description: _trimmedDesc, notes: _trimmedNotes,
          tempScale: _tempScale, maxCone: _maxCone, isPublic: _isPublic,
          segments: _builtSegments,
        );
        ref.invalidate(schedulesListProvider);
        if (mounted) context.pushReplacement('/schedule/$id');
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
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name is required')));
      return;
    }
    setState(() => _saving = true);
    try {
      final id = widget.existing!.id;
      await ref.read(schedulesRepositoryProvider).createRevision(id,
          name: name, description: _trimmedDesc, notes: _trimmedNotes,
          tempScale: _tempScale, maxCone: _maxCone, isPublic: _isPublic,
          segments: _builtSegments,
          linkedRecipeIds: _linkedRecipeIds);
      ref.invalidate(scheduleDetailProvider(id));
      ref.invalidate(scheduleRevisionsProvider(id));
      ref.invalidate(schedulesListProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickLinkedRecipe() async {
    final recipes = await ref.read(recipesListProvider.future);
    if (!mounted) return;

    final available = recipes
        .where((r) => !_linkedRecipeIds.contains(r.id))
        .toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All your recipes are already linked.')));
      return;
    }

    final picked = await showDialog<RecipeSummary>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Link a Recipe'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: available.length,
            itemBuilder: (_, i) {
              final r = available[i];
              return ListTile(
                leading: const Icon(Icons.science_outlined),
                title: Text(r.name),
                subtitle: r.cone.isNotEmpty ? Text('Cone ${r.cone}') : null,
                onTap: () => Navigator.pop(ctx, r),
              );
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
        ],
      ),
    );

    if (picked != null && mounted) {
      setState(() => _linkedRecipeIds.add(picked.id));
    }
  }
}

enum _EditorAction { newRevision }

// ── Per-segment mutable state ─────────────────────────────────────────────────

class _SegmentState {
  final Key key = UniqueKey();
  final TextEditingController lowCtrl;
  final TextEditingController highCtrl;
  final TextEditingController rateCtrl;
  final TextEditingController holdCtrl;
  final TextEditingController noteCtrl;

  _SegmentState()
      : lowCtrl  = TextEditingController(),
        highCtrl = TextEditingController(),
        rateCtrl = TextEditingController(),
        holdCtrl = TextEditingController(),
        noteCtrl = TextEditingController();

  _SegmentState.fromSegment(FiringSegment s)
      : lowCtrl  = TextEditingController(
            text: s.lowTemp != null ? s.lowTemp!.toStringAsFixed(0) : ''),
        highCtrl = TextEditingController(
            text: s.highTemp != null ? s.highTemp!.toStringAsFixed(0) : ''),
        rateCtrl = TextEditingController(
            text: s.ratePerHour != null
                ? s.ratePerHour!.toStringAsFixed(0)
                : ''),
        holdCtrl = TextEditingController(
            text: s.holdMinutes != null
                ? s.holdMinutes!.toStringAsFixed(0)
                : ''),
        noteCtrl = TextEditingController(text: s.note ?? '');

  void dispose() {
    lowCtrl.dispose();
    highCtrl.dispose();
    rateCtrl.dispose();
    holdCtrl.dispose();
    noteCtrl.dispose();
  }
}

// ── Compact segment tile ──────────────────────────────────────────────────────

class _SegmentTile extends StatelessWidget {
  const _SegmentTile({
    super.key,
    required this.state,
    required this.index,
    required this.scale,
    required this.onEdit,
    required this.onRemove,
  });
  final _SegmentState state;
  final int index;
  final String scale;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final low  = double.tryParse(state.lowCtrl.text);
    final high = double.tryParse(state.highCtrl.text);
    final rate = double.tryParse(state.rateCtrl.text);
    final hold = double.tryParse(state.holdCtrl.text);
    final note = state.noteCtrl.text.trim();

    String fmtT(double? v) =>
        v != null ? '${v.toStringAsFixed(0)}°$scale' : '—';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Segment ${index + 1}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(
                      '${fmtT(low)} → ${fmtT(high)}'
                      '${rate != null ? "  •  ${rate.toStringAsFixed(0)}°/hr" : ""}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (hold != null && hold > 0)
                      Text('Hold: ${hold.toStringAsFixed(0)} min',
                          style: Theme.of(context).textTheme.bodySmall),
                    if (note.isNotEmpty)
                      Text(
                        note,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontStyle: FontStyle.italic),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                onPressed: onEdit,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: onRemove,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Segment add/edit modal ────────────────────────────────────────────────────

class _SegmentModal extends StatefulWidget {
  const _SegmentModal({
    required this.index,
    required this.allSegments,
    required this.scale,
    required this.onConfirm,
  });
  final int index;
  final List<FiringSegment> allSegments;
  final String scale;
  final void Function(FiringSegment) onConfirm;

  @override
  State<_SegmentModal> createState() => _SegmentModalState();
}

class _SegmentModalState extends State<_SegmentModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _lowCtrl;
  late final TextEditingController _highCtrl;
  late final TextEditingController _rateCtrl;
  late final TextEditingController _holdCtrl;
  late final TextEditingController _noteCtrl;
  Timer? _refreshDebounce;

  // The "From" field is locked to the previous segment's "To" for all segments
  // after the first — the kiln can't teleport between segments.
  double? get _lockedLow {
    if (widget.index <= 0) return null;
    final prevIdx = widget.index - 1;
    if (prevIdx >= widget.allSegments.length) return null;
    return widget.allSegments[prevIdx].highTemp;
  }

  @override
  void initState() {
    super.initState();
    final existing = widget.index < widget.allSegments.length
        ? widget.allSegments[widget.index]
        : null;
    final locked = _lockedLow;
    _lowCtrl  = TextEditingController(
        text: locked?.toStringAsFixed(0)
           ?? existing?.lowTemp?.toStringAsFixed(0)
           ?? '');
    _highCtrl = TextEditingController(
        text: existing?.highTemp?.toStringAsFixed(0) ?? '');
    _rateCtrl = TextEditingController(
        text: existing?.ratePerHour?.toStringAsFixed(0) ?? '');
    _holdCtrl = TextEditingController(
        text: existing?.holdMinutes?.toStringAsFixed(0) ?? '');
    _noteCtrl = TextEditingController(text: existing?.note ?? '');
    for (final c in [_lowCtrl, _highCtrl, _rateCtrl, _holdCtrl]) {
      c.addListener(_refresh);
    }
  }

  void _refresh() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 150), () {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshDebounce?.cancel();
    for (final c in [_lowCtrl, _highCtrl, _rateCtrl, _holdCtrl, _noteCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  List<FiringSegment> get _previewSegments {
    final live = FiringSegment(
      lowTemp:     double.tryParse(_lowCtrl.text),
      highTemp:    double.tryParse(_highCtrl.text),
      ratePerHour: double.tryParse(_rateCtrl.text),
      holdMinutes: double.tryParse(_holdCtrl.text),
    );
    final all = List<FiringSegment>.from(widget.allSegments);
    if (widget.index < all.length) {
      all[widget.index] = live;
    } else {
      all.add(live);
    }
    return all;
  }

  String? _validateTemp(String? v) {
    if (v == null || v.isEmpty) return null;
    final d = double.tryParse(v);
    if (d == null) return 'Invalid';
    final mn = tempMin(widget.scale);
    final mx = tempMax(widget.scale);
    if (d < mn) return 'Min ${mn.toStringAsFixed(0)}°';
    if (d > mx) return 'Max ${mx.toStringAsFixed(0)}°';
    return null;
  }

  String? _validateHighTemp(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    return _validateTemp(v);
  }

  String? _validateRate(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final d = double.tryParse(v);
    if (d == null) return 'Invalid number';
    if (d <= 0) return 'Must be > 0';
    if (d > 9999) return 'Max 9999°/hr';
    if (d != d.roundToDouble()) return 'Whole numbers only';
    return null;
  }

  String? _validateHold(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final d = double.tryParse(v);
    if (d == null) return 'Invalid number';
    if (d < 0) return 'Must be ≥ 0';
    if (d > 1440) return 'Max 1440 min (24 hrs)';
    return null;
  }

  void _confirm() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.onConfirm(FiringSegment(
      lowTemp:     double.tryParse(_lowCtrl.text),
      highTemp:    double.tryParse(_highCtrl.text),
      ratePerHour: double.tryParse(_rateCtrl.text),
      holdMinutes: double.tryParse(_holdCtrl.text),
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isNew    = widget.index >= widget.allSegments.length;
    final segLabel = 'Segment ${widget.index + 1}';
    final preview  = _previewSegments;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                isNew ? 'Add $segLabel' : 'Edit $segLabel',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(children: [
                      if (_lockedLow != null)
                        Expanded(
                          child: TextFormField(
                            controller: _lowCtrl,
                            enabled: false,
                            decoration: InputDecoration(
                              labelText: 'From °${widget.scale}',
                              helperText: 'Continues from previous',
                              isDense: true,
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.lock_outline, size: 16),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        )
                      else
                        _ModalField(
                          ctrl: _lowCtrl,
                          label: 'From °${widget.scale}',
                          validator: _validateTemp,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                            LengthLimitingTextInputFormatter(7),
                          ],
                        ),
                      const SizedBox(width: 8),
                      _ModalField(
                        ctrl: _highCtrl,
                        label: 'To °${widget.scale}',
                        validator: _validateHighTemp,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                          LengthLimitingTextInputFormatter(7),
                        ],
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      _ModalField(
                        ctrl: _rateCtrl,
                        label: 'Rate/hr °${widget.scale}',
                        validator: _validateRate,
                        keyboardType: const TextInputType.numberWithOptions(decimal: false),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                      ),
                      const SizedBox(width: 8),
                      _ModalField(
                        ctrl: _holdCtrl,
                        label: 'Hold (min)',
                        validator: _validateHold,
                        keyboardType: const TextInputType.numberWithOptions(decimal: false),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                      ),
                    ]),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _noteCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Note (optional)',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FiringChart(
                segments: preview,
                scale: widget.scale,
                height: 160,
                showTitle: false,
                showLegend: false,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _confirm,
                    child: Text(isNew ? 'Add Segment' : 'Update'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModalField extends StatelessWidget {
  const _ModalField({
    required this.ctrl,
    required this.label,
    this.validator,
    this.keyboardType = const TextInputType.numberWithOptions(decimal: true),
    this.inputFormatters,
  });
  final TextEditingController ctrl;
  final String label;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) => Expanded(
        child: TextFormField(
          controller: ctrl,
          decoration: InputDecoration(
            labelText: label,
            isDense: true,
            border: const OutlineInputBorder(),
          ),
          keyboardType: keyboardType,
          validator: validator,
          inputFormatters: inputFormatters,
        ),
      );
}

// ── Linked recipe chip with name lookup ───────────────────────────────────────

class _LinkedRecipeChip extends ConsumerWidget {
  const _LinkedRecipeChip({
    required this.recipeId,
    required this.onRemove,
  });
  final String recipeId;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(recipesListProvider);
    final name = recipesAsync.valueOrNull
        ?.firstWhere((r) => r.id == recipeId,
            orElse: () => RecipeSummary(
                  id: recipeId,
                  uid: '', name: recipeId, cone: '',
                  firingType: '', isPublic: false, likeCount: 0,
                  revisionCount: 1, imageUrl: '', status: 'New',
                  dateCreated: '', dateModified: '',
                ))
        .name ?? recipeId;

    return Chip(
      avatar: const Icon(Icons.science_outlined, size: 14),
      label: Text(name, style: const TextStyle(fontSize: 12)),
      deleteIcon: const Icon(Icons.close, size: 14),
      onDeleted: onRemove,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
