import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../recipes/recipes_repository.dart';
import 'firing_chart.dart';
import 'schedule_models.dart';
import 'schedules_repository.dart';

class ScheduleDetailScreen extends ConsumerWidget {
  const ScheduleDetailScreen({super.key, required this.scheduleId});
  final String scheduleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(scheduleDetailProvider(scheduleId));
    return async.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Firing Schedule')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Firing Schedule')),
        body: Center(child: Text('$e')),
      ),
      data: (schedule) => _ScheduleView(schedule: schedule),
    );
  }
}

class _ScheduleView extends ConsumerStatefulWidget {
  const _ScheduleView({required this.schedule});
  final ScheduleDetail schedule;

  @override
  ConsumerState<_ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends ConsumerState<_ScheduleView> {
  ScheduleRevision? _selectedRevision;
  int? _restoringRevNum;

  ScheduleRevision? get _revision =>
      _selectedRevision ?? widget.schedule.revision;

  @override
  void didUpdateWidget(_ScheduleView old) {
    super.didUpdateWidget(old);
    if (widget.schedule.dateModified != old.schedule.dateModified) {
      if (widget.schedule.revisionCount > old.schedule.revisionCount) {
        // New revision created — always show the new latest.
        _selectedRevision = null;
        _restoringRevNum = null;
      } else if (_selectedRevision == null ||
          _selectedRevision!.revisionNum == widget.schedule.revisionCount) {
        // Latest revision updated in-place — clear stale snapshot.
        _selectedRevision = null;
        _restoringRevNum = null;
      } else {
        // Non-latest revision updated in-place — re-fetch fresh data for it.
        _restoreRevision(_selectedRevision!.revisionNum);
      }
    }
  }

  Future<void> _restoreRevision(int revNum) async {
    _restoringRevNum = revNum;
    try {
      final revisions =
          await ref.read(scheduleRevisionsProvider(widget.schedule.id).future);
      if (!mounted || _restoringRevNum != revNum) return;
      ScheduleRevision? fresh;
      try {
        fresh = revisions.firstWhere((r) => r.revisionNum == revNum);
      } catch (_) {}
      setState(() {
        _selectedRevision = fresh;
        _restoringRevNum = null;
      });
    } catch (_) {
      if (mounted && _restoringRevNum == revNum) {
        setState(() {
          _selectedRevision = null;
          _restoringRevNum = null;
        });
      }
    }
  }

  Future<void> _openEditor(ScheduleRevision? targetRevision) async {
    final schedule = widget.schedule;
    final editTarget = (targetRevision != null && targetRevision != schedule.revision)
        ? schedule.copyWith(revision: targetRevision)
        : schedule;
    final savedRevision = await context.push<ScheduleRevision?>(
        '/schedule/${schedule.id}/edit',
        extra: editTarget);
    if (!mounted) return;
    if (savedRevision != null) {
      setState(() => _selectedRevision = savedRevision);
    }
  }

  void _showRevisionHistory() {
    final embedded = widget.schedule.revisions;
    final future = embedded.isNotEmpty
        ? null
        : ref.read(scheduleRevisionsProvider(widget.schedule.id).future);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _RevisionHistorySheet(
        embedded: embedded,
        future: future,
        current: _revision,
        latestRevisionNum: widget.schedule.revisionCount,
        onSelect: (rev) {
          setState(() => _selectedRevision = rev);
          Navigator.pop(ctx);
        },
        onEdit: (rev) {
          Navigator.pop(ctx);
          _openEditor(rev);
        },
      ),
    );
  }

  Future<void> _duplicateSchedule() async {
    final schedule = widget.schedule;
    final nameCtrl = TextEditingController(text: '${schedule.name} (Copy)');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Duplicate Schedule'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'New name'),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Duplicate')),
        ],
      ),
    );
    final pickedName = nameCtrl.text.trim();
    nameCtrl.dispose();
    if (confirmed != true || !mounted) return;

    try {
      final revision = _revision;
      final newId = await ref.read(schedulesRepositoryProvider).createSchedule(
        name: pickedName.isEmpty ? '${schedule.name} (Copy)' : pickedName,
        description: schedule.description.isEmpty ? null : schedule.description,
        notes: schedule.notes.isEmpty ? null : schedule.notes,
        tempScale: schedule.tempScale.isEmpty ? 'F' : schedule.tempScale,
        maxCone: schedule.maxCone.isEmpty ? null : schedule.maxCone,
        isPublic: false,
        segments: revision?.segments ?? [],
      );
      ref.invalidate(schedulesListProvider);
      if (mounted) context.push('/schedule/$newId');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final schedule = widget.schedule;
    final revision = _revision;
    final segments = revision?.segments ?? [];
    final scale    = schedule.tempScale;
    final scheme   = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(schedule.name),
        actions: [
          if (schedule.revisionCount > 1)
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'Version history',
              onPressed: _showRevisionHistory,
            ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _openEditor(_selectedRevision),
          ),
          PopupMenuButton<_DetailAction>(
            onSelected: (action) {
              switch (action) {
                case _DetailAction.duplicate: _duplicateSchedule();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _DetailAction.duplicate,
                child: ListTile(
                  leading: Icon(Icons.copy_outlined),
                  title: Text('Duplicate'),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(scheduleDetailProvider(schedule.id));
          ref.invalidate(scheduleRevisionsProvider(schedule.id));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Revision indicator when viewing a non-latest revision
            if (_selectedRevision != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.history, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Viewing v${_selectedRevision!.revisionNum}'
                      '${_selectedRevision!.dateCreated.isNotEmpty ? " — ${_selectedRevision!.dateCreated}" : ""}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () =>
                          setState(() => _selectedRevision = null),
                      style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero),
                      child: const Text('Latest'),
                    ),
                  ],
                ),
              ),

            // Metadata chips
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (schedule.maxCone.isNotEmpty)
                  _Chip(
                      label: 'Cone ${schedule.maxCone}',
                      icon: Icons.thermostat_outlined),
                _Chip(label: '°$scale', icon: Icons.device_thermostat),
                if (schedule.isPublic)
                  _Chip(label: 'Public', icon: Icons.public),
                if (schedule.revisionCount > 1)
                  ActionChip(
                    avatar: const Icon(Icons.history, size: 14),
                    label: Text(
                        'v${revision?.revisionNum ?? schedule.revisionCount}',
                        style: const TextStyle(fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    labelPadding:
                        const EdgeInsets.symmetric(horizontal: 4),
                    onPressed: _showRevisionHistory,
                  ),
              ],
            ),

            if (schedule.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(schedule.description),
            ],

            if (segments.isNotEmpty) ...[
              const SizedBox(height: 24),
              FiringChart(segments: segments, scale: scale),
            ],

            const SizedBox(height: 24),
            Text('Firing Segments',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),

            if (segments.isEmpty)
              const Text('No segments defined.',
                  style: TextStyle(color: Colors.grey))
            else ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                        flex: 2,
                        child: Text('From',
                            style: Theme.of(context).textTheme.labelSmall)),
                    Expanded(
                        flex: 2,
                        child: Text('To',
                            style: Theme.of(context).textTheme.labelSmall)),
                    Expanded(
                        flex: 2,
                        child: Text('Rate/hr',
                            style: Theme.of(context).textTheme.labelSmall)),
                    Expanded(
                        flex: 2,
                        child: Text('Hold',
                            style: Theme.of(context).textTheme.labelSmall)),
                  ],
                ),
              ),
              const Divider(height: 1),
              ...segments.asMap().entries.map((entry) {
                final i   = entry.key;
                final seg = entry.value;
                return _SegmentRow(segment: seg, index: i, scale: scale);
              }),
            ],

            // Linked recipes
            if (revision != null && revision.linkedRecipeIds.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Linked Recipes',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _LinkedRecipes(recipeIds: revision.linkedRecipeIds),
            ],

            if (schedule.notes.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Notes', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(schedule.notes),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

enum _DetailAction { duplicate }

// ── Linked recipes ────────────────────────────────────────────────────────────

class _LinkedRecipes extends ConsumerWidget {
  const _LinkedRecipes({required this.recipeIds});
  final List<String> recipeIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(recipesListProvider);
    return recipesAsync.when(
      loading: () => Wrap(
        spacing: 8,
        runSpacing: 4,
        children: recipeIds
            .map((id) => ActionChip(
                  avatar: const Icon(Icons.science_outlined, size: 14),
                  label: Text(id, style: const TextStyle(fontSize: 12)),
                  onPressed: () => context.push('/recipe/$id'),
                ))
            .toList(),
      ),
      error: (_, __) => Wrap(
        spacing: 8,
        runSpacing: 4,
        children: recipeIds
            .map((id) => ActionChip(
                  avatar: const Icon(Icons.science_outlined, size: 14),
                  label: Text(id, style: const TextStyle(fontSize: 12)),
                  onPressed: () => context.push('/recipe/$id'),
                ))
            .toList(),
      ),
      data: (recipes) {
        final nameMap = {for (final r in recipes) r.id: r.name};
        return Wrap(
          spacing: 8,
          runSpacing: 4,
          children: recipeIds.map((id) {
            final name = nameMap[id] ?? id;
            return ActionChip(
              avatar: const Icon(Icons.science_outlined, size: 14),
              label: Text(name, style: const TextStyle(fontSize: 12)),
              onPressed: () => context.push('/recipe/$id'),
            );
          }).toList(),
        );
      },
    );
  }
}

// ── Revision history sheet ────────────────────────────────────────────────────

class _RevisionHistorySheet extends StatefulWidget {
  const _RevisionHistorySheet({
    required this.embedded,
    required this.future,
    required this.current,
    required this.latestRevisionNum,
    required this.onSelect,
    required this.onEdit,
  });
  final List<ScheduleRevision> embedded;
  final Future<List<ScheduleRevision>>? future;
  final ScheduleRevision? current;
  final int latestRevisionNum;
  final void Function(ScheduleRevision) onSelect;
  final void Function(ScheduleRevision) onEdit;

  @override
  State<_RevisionHistorySheet> createState() => _RevisionHistorySheetState();
}

class _RevisionHistorySheetState extends State<_RevisionHistorySheet> {
  List<ScheduleRevision>? _revisions;
  bool _loading = false;
  bool _compareMode = false;
  final Set<int> _compareSelected = {};

  @override
  void initState() {
    super.initState();
    if (widget.embedded.isNotEmpty) {
      _revisions = widget.embedded;
    } else if (widget.future != null) {
      _loading = true;
      widget.future!.then((revs) {
        if (mounted) setState(() { _revisions = revs; _loading = false; });
      }).catchError((_) {
        if (mounted) setState(() { _revisions = []; _loading = false; });
      });
    } else {
      _revisions = [];
    }
  }

  void _toggleCompare(int revNum) {
    setState(() {
      if (_compareSelected.contains(revNum)) {
        _compareSelected.remove(revNum);
      } else if (_compareSelected.length < 2) {
        _compareSelected.add(revNum);
      }
    });
  }

  void _showDiff() {
    final revisions = _revisions ?? [];
    final nums = _compareSelected.toList()..sort();
    final a = revisions.firstWhere((r) => r.revisionNum == nums[0]);
    final b = revisions.firstWhere((r) => r.revisionNum == nums[1]);
    Navigator.pop(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => _ScheduleDiffDialog(vA: a, vB: b),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final revisions = _revisions ?? [];
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, sc) => Column(
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
            child: Row(
              children: [
                Text('Version History',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (revisions.length >= 2)
                  TextButton.icon(
                    icon: Icon(_compareMode ? Icons.close : Icons.compare_arrows,
                        size: 16),
                    label: Text(_compareMode ? 'Cancel' : 'Compare'),
                    style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact),
                    onPressed: () => setState(() {
                      _compareMode = !_compareMode;
                      _compareSelected.clear();
                    }),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : revisions.isEmpty
                    ? const Center(child: Text('No revision history found.'))
                    : ListView(
                        controller: sc,
                        children: [
                          ...revisions.map((rev) {
                            final isCurrent = rev.revisionNum ==
                                (widget.current?.revisionNum ?? -1);
                            final isLatest =
                                rev.revisionNum == widget.latestRevisionNum;
                            final isSelected =
                                _compareSelected.contains(rev.revisionNum);

                            return ListTile(
                              title: Text('Version ${rev.revisionNum}'
                                  '${isLatest ? "  (latest)" : ""}'),
                              subtitle: rev.dateCreated.isNotEmpty
                                  ? Text(rev.dateCreated)
                                  : Text('${rev.segments.length} segment'
                                      '${rev.segments.length == 1 ? "" : "s"}'),
                              leading: _compareMode
                                  ? Checkbox(
                                      value: isSelected,
                                      onChanged:
                                          (_compareSelected.length < 2 ||
                                                  isSelected)
                                              ? (_) => _toggleCompare(
                                                  rev.revisionNum)
                                              : null,
                                    )
                                  : (isCurrent
                                      ? Icon(Icons.check_circle_outline,
                                          size: 20, color: scheme.primary)
                                      : const Icon(Icons.radio_button_unchecked,
                                          size: 20, color: Colors.grey)),
                              trailing: _compareMode
                                  ? null
                                  : IconButton(
                                      icon: const Icon(Icons.edit_outlined,
                                          size: 18),
                                      tooltip: 'Edit this version',
                                      onPressed: () => widget.onEdit(rev),
                                      visualDensity: VisualDensity.compact,
                                    ),
                              onTap: _compareMode
                                  ? () => _toggleCompare(rev.revisionNum)
                                  : () => widget.onSelect(rev),
                            );
                          }),
                          const SizedBox(height: 16),
                        ],
                      ),
          ),
          if (_compareMode && _compareSelected.length == 2) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: FilledButton.icon(
                onPressed: _showDiff,
                icon: const Icon(Icons.compare_arrows),
                label: Text(
                    'Compare v${_compareSelected.reduce((a, b) => a < b ? a : b)}'
                    ' vs v${_compareSelected.reduce((a, b) => a > b ? a : b)}'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Schedule diff dialog ──────────────────────────────────────────────────────

class _ScheduleDiffDialog extends StatelessWidget {
  const _ScheduleDiffDialog({required this.vA, required this.vB});
  final ScheduleRevision vA;
  final ScheduleRevision vB;

  @override
  Widget build(BuildContext context) {
    final aSegs = vA.segments;
    final bSegs = vB.segments;
    final maxLen = aSegs.length > bSegs.length ? aSegs.length : bSegs.length;

    final rows = <Widget>[];
    for (var i = 0; i < maxLen; i++) {
      final segLabel = 'Segment ${i + 1}';
      if (i >= aSegs.length) {
        rows.add(_DiffSegRow(
            label: segLabel, change: _SegChange.added, b: bSegs[i]));
      } else if (i >= bSegs.length) {
        rows.add(_DiffSegRow(
            label: segLabel, change: _SegChange.removed, a: aSegs[i]));
      } else {
        final a = aSegs[i];
        final b = bSegs[i];
        final same = a.lowTemp == b.lowTemp &&
            a.highTemp == b.highTemp &&
            a.ratePerHour == b.ratePerHour &&
            a.holdMinutes == b.holdMinutes;
        rows.add(_DiffSegRow(
            label: segLabel,
            change: same ? _SegChange.same : _SegChange.changed,
            a: a,
            b: b));
      }
    }

    // Linked recipe changes
    final aLinks = vA.linkedRecipeIds.toSet();
    final bLinks = vB.linkedRecipeIds.toSet();
    final addedLinks   = bLinks.difference(aLinks);
    final removedLinks = aLinks.difference(bLinks);
    if (addedLinks.isNotEmpty || removedLinks.isNotEmpty) {
      rows.add(const Divider());
      for (final id in addedLinks) {
        rows.add(Container(
          color: Colors.green.withAlpha(30),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(children: [
            const Icon(Icons.science_outlined, size: 14),
            const SizedBox(width: 6),
            Text('+ Linked: $id', style: const TextStyle(fontSize: 12)),
          ]),
        ));
      }
      for (final id in removedLinks) {
        rows.add(Container(
          color: Colors.red.withAlpha(30),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(children: [
            const Icon(Icons.science_outlined, size: 14),
            const SizedBox(width: 6),
            Text('− Unlinked: $id', style: const TextStyle(fontSize: 12)),
          ]),
        ));
      }
    }

    return AlertDialog(
      title: Text('v${vA.revisionNum} vs v${vB.revisionNum}'),
      content: SizedBox(
        width: double.maxFinite,
        child: rows.isEmpty
            ? const Text('No differences found.')
            : ListView(shrinkWrap: true, children: rows),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close')),
      ],
    );
  }
}

enum _SegChange { added, removed, changed, same }

class _DiffSegRow extends StatelessWidget {
  const _DiffSegRow({
    required this.label,
    required this.change,
    this.a,
    this.b,
  });
  final String label;
  final _SegChange change;
  final FiringSegment? a;
  final FiringSegment? b;

  @override
  Widget build(BuildContext context) {
    Color bg;
    switch (change) {
      case _SegChange.added:    bg = Colors.green.withAlpha(30);
      case _SegChange.removed:  bg = Colors.red.withAlpha(30);
      case _SegChange.changed:  bg = Colors.orange.withAlpha(30);
      case _SegChange.same:     bg = Colors.transparent;
    }

    String fmtSeg(FiringSegment? s) {
      if (s == null) return '—';
      final from = s.lowTemp?.toStringAsFixed(0) ?? '?';
      final to   = s.highTemp?.toStringAsFixed(0) ?? '?';
      final rate = s.ratePerHour?.toStringAsFixed(0);
      final hold = s.holdMinutes?.toStringAsFixed(0);
      var txt = '$from → $to°';
      if (rate != null) txt += '  $rate°/hr';
      if (hold != null && hold != '0') txt += '  hold ${hold}m';
      return txt;
    }

    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          if (change == _SegChange.same || change == _SegChange.removed)
            Text(fmtSeg(a), style: const TextStyle(fontSize: 12)),
          if (change == _SegChange.added)
            Text(fmtSeg(b),
                style: const TextStyle(fontSize: 12, color: Colors.green)),
          if (change == _SegChange.changed) ...[
            Text('was: ${fmtSeg(a)}',
                style: TextStyle(
                    fontSize: 12, color: Colors.red.shade700)),
            Text('now: ${fmtSeg(b)}',
                style: TextStyle(
                    fontSize: 12, color: Colors.green.shade700)),
          ],
        ],
      ),
    );
  }
}

// ── Segment row ───────────────────────────────────────────────────────────────

class _SegmentRow extends StatelessWidget {
  const _SegmentRow(
      {required this.segment, required this.index, required this.scale});
  final FiringSegment segment;
  final int index;
  final String scale;

  @override
  Widget build(BuildContext context) {
    String fmt(double? v) =>
        v != null ? '${v.toStringAsFixed(0)}°$scale' : '—';
    String fmtRate(double? v) =>
        v != null ? '${v.toStringAsFixed(0)}°' : '—';
    String fmtHold(double? v) =>
        v != null ? '${v.toStringAsFixed(0)} min' : '—';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(
                color: Theme.of(context).dividerColor, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text(fmt(segment.lowTemp),
                  style: const TextStyle(fontSize: 13))),
          Expanded(
              flex: 2,
              child: Text(fmt(segment.highTemp),
                  style: const TextStyle(fontSize: 13))),
          Expanded(
              flex: 2,
              child: Text(fmtRate(segment.ratePerHour),
                  style: const TextStyle(fontSize: 13))),
          Expanded(
              flex: 2,
              child: Text(fmtHold(segment.holdMinutes),
                  style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

// ── Chip ──────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Chip(
        avatar: Icon(icon, size: 14),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      );
}
