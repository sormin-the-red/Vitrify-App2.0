import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart' show statusColor;
import '../schedules/schedule_models.dart';
import '../schedules/schedules_repository.dart';
import 'recipe_models.dart';
import 'recipes_repository.dart';

class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({super.key});

  @override
  ConsumerState<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Studio'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: FilledButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: Text(_tabs.index == 0 ? 'New Recipe' : 'New Schedule'),
              onPressed: () => _tabs.index == 0
                  ? context.push('/recipe/new')
                  : context.push('/schedule/new'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push('/profile'),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Recipes'),
            Tab(text: 'Schedules'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _RecipeList(),
          _ScheduleList(),
        ],
      ),
    );
  }
}

// ── Recipe list tab ───────────────────────────────────────────────────────────

class _RecipeList extends ConsumerStatefulWidget {
  const _RecipeList();

  @override
  ConsumerState<_RecipeList> createState() => _RecipeListState();
}

class _RecipeListState extends ConsumerState<_RecipeList> {
  final Map<String, Timer> _pendingDeletes = {};

  @override
  void dispose() {
    for (final t in _pendingDeletes.values) {
      t.cancel();
    }
    super.dispose();
  }

  void _dismissRecipe(RecipeSummary recipe) {
    setState(() {
      _pendingDeletes[recipe.id]?.cancel();
      _pendingDeletes[recipe.id] = Timer(const Duration(seconds: 4), () async {
        try {
          await ref.read(recipesRepositoryProvider).deleteRecipe(recipe.id);
        } finally {
          if (mounted) {
            setState(() => _pendingDeletes.remove(recipe.id));
            ref.invalidate(recipesListProvider);
          }
        }
      });
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${recipe.name}" deleted'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            _pendingDeletes[recipe.id]?.cancel();
            setState(() => _pendingDeletes.remove(recipe.id));
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(recipesListProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(
        message: '$e',
        onRetry: () => ref.invalidate(recipesListProvider),
      ),
      data: (recipes) {
        final visible = recipes.where((r) => !_pendingDeletes.containsKey(r.id)).toList();
        if (visible.isEmpty && _pendingDeletes.isEmpty) {
          return const _EmptyView(
            icon: Icons.science_outlined,
            label: 'No recipes yet.',
            hint: 'Tap + to create your first recipe.',
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(recipesListProvider),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
            itemCount: visible.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final recipe = visible[i];
              return Dismissible(
                key: ValueKey(recipe.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.delete_outline,
                      color: Theme.of(context).colorScheme.onError),
                ),
                onDismissed: (_) => _dismissRecipe(recipe),
                child: _RecipeCard(
                  recipe: recipe,
                  onDelete: () => _confirmDelete(context, recipe),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, RecipeSummary recipe) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete recipe?'),
        content: Text(
            'Delete "${recipe.name}" and all its revisions? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error, foregroundColor: Theme.of(context).colorScheme.onError),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(recipesRepositoryProvider)
                    .deleteRecipe(recipe.id);
                ref.invalidate(recipesListProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.recipe, required this.onDelete});
  final RecipeSummary recipe;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sc = statusColor(recipe.status);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/recipe/${recipe.id}'),
        onLongPress: onDelete,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              recipe.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(recipe.imageUrl,
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const _RecipeIcon()),
                    )
                  : const _RecipeIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(recipe.name,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (recipe.cone.isNotEmpty)
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.change_history,
                                size: 11, color: scheme.onSurfaceVariant),
                            const SizedBox(width: 2),
                            Text('Cone ${recipe.cone}',
                                style: Theme.of(context).textTheme.bodySmall),
                          ]),
                        if (recipe.firingType.isNotEmpty)
                          Text(recipe.firingType,
                              style: Theme.of(context).textTheme.bodySmall),
                        if (recipe.finish.isNotEmpty)
                          _AttrPill(label: recipe.finish),
                        if (recipe.surface.isNotEmpty)
                          _AttrPill(label: recipe.surface),
                        if (recipe.transparency.isNotEmpty)
                          _AttrPill(label: recipe.transparency),
                        ...recipe.color.map((c) => _AttrPill(label: c)),
                        if (recipe.status != 'New')
                          _StatusPill(label: recipe.status, color: sc),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (recipe.isPublic)
                    Icon(Icons.public, size: 15, color: scheme.primary),
                  if (recipe.revisionCount > 1) ...[
                    const SizedBox(height: 2),
                    Text('v${recipe.revisionCount}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant)),
                  ],
                ],
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecipeIcon extends StatelessWidget {
  const _RecipeIcon();
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer,
            scheme.primaryContainer.withValues(alpha: 0.55),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.science_outlined,
          color: scheme.onPrimaryContainer, size: 26),
    );
  }
}

// ── Schedule list tab ─────────────────────────────────────────────────────────

class _ScheduleList extends ConsumerStatefulWidget {
  const _ScheduleList();

  @override
  ConsumerState<_ScheduleList> createState() => _ScheduleListState();
}

class _ScheduleListState extends ConsumerState<_ScheduleList> {
  final Map<String, Timer> _pendingDeletes = {};

  @override
  void dispose() {
    for (final t in _pendingDeletes.values) {
      t.cancel();
    }
    super.dispose();
  }

  void _dismissSchedule(ScheduleSummary schedule) {
    setState(() {
      _pendingDeletes[schedule.id]?.cancel();
      _pendingDeletes[schedule.id] = Timer(const Duration(seconds: 4), () async {
        try {
          await ref.read(schedulesRepositoryProvider).deleteSchedule(schedule.id);
        } finally {
          if (mounted) {
            setState(() => _pendingDeletes.remove(schedule.id));
            ref.invalidate(schedulesListProvider);
          }
        }
      });
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${schedule.name}" deleted'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            _pendingDeletes[schedule.id]?.cancel();
            setState(() => _pendingDeletes.remove(schedule.id));
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(schedulesListProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(
        message: '$e',
        onRetry: () => ref.invalidate(schedulesListProvider),
      ),
      data: (schedules) {
        final visible = schedules.where((s) => !_pendingDeletes.containsKey(s.id)).toList();
        if (visible.isEmpty && _pendingDeletes.isEmpty) {
          return const _EmptyView(
            icon: Icons.local_fire_department_outlined,
            label: 'No firing schedules yet.',
            hint: 'Tap + to create your first schedule.',
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(schedulesListProvider),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
            itemCount: visible.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final schedule = visible[i];
              return Dismissible(
                key: ValueKey(schedule.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.delete_outline,
                      color: Theme.of(context).colorScheme.onError),
                ),
                onDismissed: (_) => _dismissSchedule(schedule),
                child: _ScheduleCard(
                  schedule: schedule,
                  onDelete: () => _confirmDelete(context, schedule),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, ScheduleSummary schedule) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete schedule?'),
        content:
            Text('Delete "${schedule.name}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error, foregroundColor: Theme.of(context).colorScheme.onError),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(schedulesRepositoryProvider)
                    .deleteSchedule(schedule.id);
                ref.invalidate(schedulesListProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.schedule, required this.onDelete});
  final ScheduleSummary schedule;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final subtitle = [
      if (schedule.maxCone.isNotEmpty) 'Cone ${schedule.maxCone}',
      '°${schedule.tempScale}',
    ].join(' · ');

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/schedule/${schedule.id}'),
        onLongPress: onDelete,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.secondaryContainer,
                      scheme.secondaryContainer.withValues(alpha: 0.55),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.local_fire_department_outlined,
                    color: scheme.onSecondaryContainer, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(schedule.name,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (schedule.isPublic)
                    Icon(Icons.public, size: 15, color: scheme.primary),
                  if (schedule.revisionCount > 1) ...[
                    const SizedBox(height: 2),
                    Text('v${schedule.revisionCount}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant)),
                  ],
                ],
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _AttrPill extends StatelessWidget {
  const _AttrPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      );
}

class _EmptyView extends StatelessWidget {
  const _EmptyView(
      {required this.icon, required this.label, required this.hint});
  final IconData icon;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 64,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.35)),
            const SizedBox(height: 20),
            Text(label,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: scheme.onSurfaceVariant),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(hint,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: scheme.error),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
