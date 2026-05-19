import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

class _ScheduleView extends ConsumerWidget {
  const _ScheduleView({required this.schedule});
  final ScheduleDetail schedule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final revision = schedule.revision;
    final segments = revision?.segments ?? [];
    final scale = schedule.tempScale;

    return Scaffold(
      appBar: AppBar(
        title: Text(schedule.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/schedule/${schedule.id}/edit',
                extra: schedule),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.invalidate(scheduleDetailProvider(schedule.id)),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Metadata chips
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (schedule.maxCone.isNotEmpty)
                  _Chip(label: 'Cone ${schedule.maxCone}',
                      icon: Icons.thermostat_outlined),
                _Chip(label: '°$scale', icon: Icons.device_thermostat),
                if (schedule.isPublic)
                  _Chip(label: 'Public', icon: Icons.public),
                if (schedule.revisionCount > 1)
                  _Chip(label: 'v${schedule.revisionCount}',
                      icon: Icons.history),
              ],
            ),

            if (schedule.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(schedule.description),
            ],

            const SizedBox(height: 24),
            Text('Firing Segments',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),

            if (segments.isEmpty)
              const Text('No segments defined.',
                  style: TextStyle(color: Colors.grey))
            else ...[
              // Header row
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                        flex: 2,
                        child: Text('From',
                            style:
                                Theme.of(context).textTheme.labelSmall)),
                    Expanded(
                        flex: 2,
                        child: Text('To',
                            style:
                                Theme.of(context).textTheme.labelSmall)),
                    Expanded(
                        flex: 2,
                        child: Text('Rate/hr',
                            style:
                                Theme.of(context).textTheme.labelSmall)),
                    Expanded(
                        flex: 2,
                        child: Text('Hold',
                            style:
                                Theme.of(context).textTheme.labelSmall)),
                  ],
                ),
              ),
              const Divider(height: 1),
              ...segments.asMap().entries.map((entry) {
                final i = entry.key;
                final seg = entry.value;
                return _SegmentRow(segment: seg, index: i, scale: scale);
              }),
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

class _SegmentRow extends StatelessWidget {
  const _SegmentRow(
      {required this.segment, required this.index, required this.scale});
  final FiringSegment segment;
  final int index;
  final String scale;

  @override
  Widget build(BuildContext context) {
    String fmt(double? v) => v != null ? '${v.toStringAsFixed(0)}°$scale' : '—';
    String fmtRate(double? v) => v != null ? '${v.toStringAsFixed(0)}°' : '—';
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
              flex: 2, child: Text(fmt(segment.lowTemp), style: const TextStyle(fontSize: 13))),
          Expanded(
              flex: 2, child: Text(fmt(segment.highTemp), style: const TextStyle(fontSize: 13))),
          Expanded(
              flex: 2,
              child: Text(fmtRate(segment.ratePerHour), style: const TextStyle(fontSize: 13))),
          Expanded(
              flex: 2,
              child: Text(fmtHold(segment.holdMinutes), style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

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
