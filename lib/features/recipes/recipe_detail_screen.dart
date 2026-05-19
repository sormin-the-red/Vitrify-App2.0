import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'recipe_models.dart';
import 'recipes_repository.dart';

class RecipeDetailScreen extends ConsumerWidget {
  const RecipeDetailScreen({super.key, required this.recipeId});
  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recipeDetailProvider(recipeId));
    return async.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Recipe')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Recipe')),
        body: Center(child: Text('$e')),
      ),
      data: (recipe) => _RecipeView(recipe: recipe),
    );
  }
}

class _RecipeView extends ConsumerWidget {
  const _RecipeView({required this.recipe});
  final RecipeDetail recipe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final revision = recipe.revision;
    final totalPct = revision?.materials.fold<double>(
            0, (sum, m) => sum + m.percentage) ??
        0;

    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () =>
                context.push('/recipe/${recipe.id}/edit', extra: recipe),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(recipeDetailProvider(recipe.id)),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Hero image
            if (recipe.imageUrl.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(recipe.imageUrl,
                    height: 200, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink()),
              ),
              const SizedBox(height: 16),
            ],

            // Metadata chips
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (recipe.cone.isNotEmpty)
                  _MetaChip(label: 'Cone ${recipe.cone}',
                      icon: Icons.thermostat_outlined),
                if (recipe.firingType.isNotEmpty)
                  _MetaChip(label: recipe.firingType,
                      icon: Icons.local_fire_department_outlined),
                if (recipe.isPublic)
                  _MetaChip(label: 'Public', icon: Icons.public),
                if (recipe.revisionCount > 1)
                  _MetaChip(
                      label: 'v${recipe.revisionCount}',
                      icon: Icons.history),
                if (recipe.likeCount > 0)
                  _MetaChip(
                      label: '${recipe.likeCount} ♥',
                      icon: Icons.favorite_outline),
              ],
            ),

            // Description
            if (recipe.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(recipe.description,
                  style: Theme.of(context).textTheme.bodyMedium),
            ],

            const SizedBox(height: 24),

            // Ingredients
            Row(
              children: [
                Text('Ingredients',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (revision != null && totalPct > 0)
                  Text(
                    '${totalPct.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: (totalPct - 100).abs() < 0.5
                          ? Colors.green
                          : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            if (revision == null || revision.materials.isEmpty)
              const Text('No ingredients.',
                  style: TextStyle(color: Colors.grey))
            else
              ...revision.materials.map((m) => _IngredientRow(
                    ingredient: m,
                    totalPct: totalPct,
                  )),

            // Notes
            if (recipe.notes.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Notes', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(recipe.notes),
            ],

            // Revision notes
            if (revision != null && revision.notes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Revision notes',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(revision.notes,
                  style: Theme.of(context).textTheme.bodySmall),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({required this.ingredient, required this.totalPct});
  final RecipeIngredient ingredient;
  final double totalPct;

  @override
  Widget build(BuildContext context) {
    final fraction = totalPct > 0 ? ingredient.percentage / totalPct : 0.0;
    final pctText = '${ingredient.percentage.toStringAsFixed(1)}%';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(ingredient.name,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction.clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 46,
            child: Text(pctText,
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.icon});
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
