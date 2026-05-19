import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _tempScale = 'F';
  String? _maxCone;
  bool _isPublic = false;
  final List<_SegmentState> _segments = [];
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameCtrl.text = e.name;
      _descCtrl.text = e.description;
      _notesCtrl.text = e.notes;
      _tempScale = e.tempScale.isEmpty ? 'F' : e.tempScale;
      _maxCone = e.maxCone.isEmpty ? null : e.maxCone;
      _isPublic = e.isPublic;
      for (final seg in e.revision?.segments ?? []) {
        _segments.add(_SegmentState.fromSegment(seg));
      }
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

  List<FiringSegment> get _builtSegments => _segments.map((s) {
        return FiringSegment(
          lowTemp: double.tryParse(s.lowCtrl.text),
          highTemp: double.tryParse(s.highCtrl.text),
          ratePerHour: double.tryParse(s.rateCtrl.text),
          holdMinutes: double.tryParse(s.holdCtrl.text),
          note: s.noteCtrl.text.trim().isEmpty ? null : s.noteCtrl.text.trim(),
        );
      }).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Schedule' : 'New Schedule'),
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
              // Temp scale toggle
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
                onPressed: () =>
                    setState(() => _segments.add(_SegmentState())),
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
                return _SegmentEditor(
                  key: s.key,
                  state: s,
                  index: i,
                  scale: _tempScale,
                  onRemove: () => setState(() => _segments.removeAt(i)),
                );
              }).toList(),
            ),

          const SizedBox(height: 20),
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
        await repo.updateSchedule(
          widget.existing!.id,
          name: name,
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          tempScale: _tempScale,
          maxCone: _maxCone,
          isPublic: _isPublic,
          segments: _builtSegments,
        );
        ref.invalidate(scheduleDetailProvider(widget.existing!.id));
        ref.invalidate(schedulesListProvider);
        if (mounted) context.pop();
      } else {
        final id = await repo.createSchedule(
          name: name,
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          tempScale: _tempScale,
          maxCone: _maxCone,
          isPublic: _isPublic,
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
}

// ── Per-segment mutable state ─────────────────────────────────────────────────

class _SegmentState {
  final Key key = UniqueKey();
  final TextEditingController lowCtrl;
  final TextEditingController highCtrl;
  final TextEditingController rateCtrl;
  final TextEditingController holdCtrl;
  final TextEditingController noteCtrl;

  _SegmentState()
      : lowCtrl = TextEditingController(),
        highCtrl = TextEditingController(),
        rateCtrl = TextEditingController(),
        holdCtrl = TextEditingController(),
        noteCtrl = TextEditingController();

  _SegmentState.fromSegment(FiringSegment s)
      : lowCtrl = TextEditingController(
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

class _SegmentEditor extends StatelessWidget {
  const _SegmentEditor({
    super.key,
    required this.state,
    required this.index,
    required this.scale,
    required this.onRemove,
  });
  final _SegmentState state;
  final int index;
  final String scale;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Segment ${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onRemove,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _TempField(ctrl: state.lowCtrl, label: 'From °$scale'),
                const SizedBox(width: 8),
                _TempField(ctrl: state.highCtrl, label: 'To °$scale'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _TempField(ctrl: state.rateCtrl, label: 'Rate/hr °$scale'),
                const SizedBox(width: 8),
                _TempField(ctrl: state.holdCtrl, label: 'Hold (min)'),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: state.noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TempField extends StatelessWidget {
  const _TempField({required this.ctrl, required this.label});
  final TextEditingController ctrl;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
        child: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            labelText: label,
            isDense: true,
            border: const OutlineInputBorder(),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
      );
}
