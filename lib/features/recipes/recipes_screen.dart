import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_gate.dart';
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
    return AuthGate(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Studio'),
          actions: [
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
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _tabs.index == 0
              ? context.push('/recipe/new')
              : context.push('/schedule/new'),
          icon: const Icon(Icons.add),
          label: Text(_tabs.index == 0 ? 'New Recipe' : 'New Schedule'),
        ),
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
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
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
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
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

  Color _statusColor(String s) => switch (s) {
        'Testing' => Colors.orange,
        'Tested'  => Colors.green,
        _         => Colors.transparent,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        leading: recipe.imageUrl.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(recipe.imageUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const _RecipeIcon()),
              )
            : const _RecipeIcon(),
        title: Text(recipe.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Wrap(
          spacing: 6,
          runSpacing: 2,
          children: [
            if (recipe.cone.isNotEmpty)
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.change_history,
                    size: 12, color: scheme.onSurfaceVariant),
                const SizedBox(width: 2),
                Text(recipe.cone,
                    style: Theme.of(context).textTheme.bodySmall),
              ]),
            if (recipe.firingType.isNotEmpty)
              Text(recipe.firingType,
                  style: Theme.of(context).textTheme.bodySmall),
            if (recipe.status != 'New')
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: _statusColor(recipe.status).withAlpha(35),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color:
                          _statusColor(recipe.status).withAlpha(140)),
                ),
                child: Text(recipe.status,
                    style: TextStyle(
                        fontSize: 10,
                        color: _statusColor(recipe.status))),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (recipe.isPublic)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.public, size: 16, color: Colors.green),
              ),
            if (recipe.revisionCount > 1)
              Text('v${recipe.revisionCount}',
                  style: Theme.of(context).textTheme.bodySmall),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () => context.push('/recipe/${recipe.id}'),
        onLongPress: onDelete,
      ),
    );
  }
}

class _RecipeIcon extends StatelessWidget {
  const _RecipeIcon();
  @override
  Widget build(BuildContext context) => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(Icons.science_outlined,
            color: Theme.of(context).colorScheme.onPrimaryContainer),
      );
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
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
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
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
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
    final subtitle = [
      if (schedule.maxCone.isNotEmpty) 'Cone ${schedule.maxCone}',
      '°${schedule.tempScale}',
    ].join(' · ');

    return Card(
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(Icons.local_fire_department_outlined,
              color: Theme.of(context).colorScheme.onSecondaryContainer),
        ),
        title: Text(schedule.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (schedule.isPublic)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.public, size: 16, color: Colors.green),
              ),
            if (schedule.revisionCount > 1)
              Text('v${schedule.revisionCount}',
                  style: Theme.of(context).textTheme.bodySmall),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () => context.push('/schedule/${schedule.id}'),
        onLongPress: onDelete,
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView(
      {required this.icon, required this.label, required this.hint});
  final IconData icon;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(label,
                style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(hint, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
}
