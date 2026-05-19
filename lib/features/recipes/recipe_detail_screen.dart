import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/chemistry/umf_calculator.dart';
import '../../core/materials/materials_repository.dart';
import 'recipe_models.dart';
import 'recipes_repository.dart';

// Status display config
Color _statusColor(String status) => switch (status) {
      'Testing' => Colors.orange,
      'Tested'  => Colors.green,
      _         => Colors.grey,
    };

class RecipeDetailScreen extends ConsumerWidget {
  const RecipeDetailScreen({super.key, required this.recipeId});
  final String recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recipeDetailProvider(recipeId));
    return async.when(
      loading: () => Scaffold(
          appBar: AppBar(title: const Text('Recipe')),
          body: const Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
          appBar: AppBar(title: const Text('Recipe')),
          body: Center(child: Text('$e'))),
      data: (recipe) => _RecipeView(recipe: recipe),
    );
  }
}

// ── Recipe view (stateful so revision selection can be tracked) ───────────────

class _RecipeView extends ConsumerStatefulWidget {
  const _RecipeView({required this.recipe});
  final RecipeDetail recipe;

  @override
  ConsumerState<_RecipeView> createState() => _RecipeViewState();
}

class _RecipeViewState extends ConsumerState<_RecipeView> {
  RecipeRevision? _selectedRevision;

  RecipeRevision? get _revision =>
      _selectedRevision ?? widget.recipe.revision;

  void _showRevisionHistory() async {
    final revisionsAsync =
        await ref.read(recipeRevisionsProvider(widget.recipe.id).future);

    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => _RevisionHistorySheet(
        revisions: revisionsAsync,
        current: _revision,
        onSelect: (rev) {
          setState(() => _selectedRevision = rev);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recipe   = widget.recipe;
    final revision = _revision;
    final scheme   = Theme.of(context).colorScheme;

    final baseMaterials = revision?.materials.where((m) => !m.isAddition).toList() ?? [];
    final addMaterials  = revision?.materials.where((m) => m.isAddition).toList() ?? [];
    final basePct       = baseMaterials.fold<double>(0, (s, m) => s + m.percentage);
    final addPct        = addMaterials.fold<double>(0, (s, m) => s + m.percentage);

    final status        = revision?.status ?? recipe.status;
    final imageUrls     = (revision?.imageUrls.isNotEmpty ?? false)
        ? revision!.imageUrls
        : (recipe.imageUrl.isNotEmpty ? [recipe.imageUrl] : <String>[]);

    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.name),
        actions: [
          if (recipe.revisionCount > 1)
            IconButton(
              icon: const Icon(Icons.history),
              tooltip: 'Version history',
              onPressed: _showRevisionHistory,
            ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () =>
                context.push('/recipe/${recipe.id}/edit', extra: recipe),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.invalidate(recipeDetailProvider(recipe.id)),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Revision indicator ───────────────────────────────────────────
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
                        'Viewing v${_selectedRevision!.revisionNum} — '
                        '${_selectedRevision!.dateCreated}',
                        style: Theme.of(context).textTheme.bodySmall),
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

            // ── Photo carousel ───────────────────────────────────────────────
            if (imageUrls.isNotEmpty) ...[
              _PhotoCarousel(urls: imageUrls),
              const SizedBox(height: 16),
            ],

            // ── Metadata chips ────────────────────────────────────────────────
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (recipe.cone.isNotEmpty) _ConeChip(cone: recipe.cone),
                if (recipe.firingType.isNotEmpty)
                  _MetaChip(
                      label: recipe.firingType,
                      icon: Icons.local_fire_department_outlined),
                _StatusChip(status: status),
                if (recipe.isPublic)
                  _MetaChip(label: 'Public', icon: Icons.public),
                if (recipe.revisionCount > 1)
                  _MetaChip(
                      label: 'v${revision?.revisionNum ?? recipe.revisionCount}',
                      icon: Icons.history),
                if (recipe.likeCount > 0)
                  _MetaChip(
                      label: '${recipe.likeCount} ♥',
                      icon: Icons.favorite_outline),
              ],
            ),

            // ── Description ───────────────────────────────────────────────────
            if (recipe.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(recipe.description,
                  style: Theme.of(context).textTheme.bodyMedium),
            ],

            const SizedBox(height: 24),

            // ── Base ingredients ──────────────────────────────────────────────
            Row(
              children: [
                Text('Ingredients',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (basePct > 0)
                  Text(
                    '${basePct.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: (basePct - 100).abs() < 0.5
                          ? Colors.green
                          : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            if (baseMaterials.isEmpty)
              const Text('No ingredients.',
                  style: TextStyle(color: Colors.grey))
            else
              ...baseMaterials
                  .map((m) => _IngredientRow(ingredient: m, totalPct: basePct)),

            // ── Additions ─────────────────────────────────────────────────────
            if (addMaterials.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: Divider(color: scheme.outlineVariant)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Additions  ${addPct.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant),
                  ),
                ),
                Expanded(child: Divider(color: scheme.outlineVariant)),
              ]),
              const SizedBox(height: 8),
              ...addMaterials
                  .map((m) => _IngredientRow(ingredient: m, totalPct: addPct)),
            ],

            // ── Notes ─────────────────────────────────────────────────────────
            if (recipe.notes.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Notes', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(recipe.notes),
            ],
            if (revision != null && revision.notes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Revision notes',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(revision.notes,
                  style: Theme.of(context).textTheme.bodySmall),
            ],

            // ── UMF + Stull ───────────────────────────────────────────────────
            if (baseMaterials.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              _UmfSection(ingredients: baseMaterials),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ── Photo carousel ────────────────────────────────────────────────────────────

class _PhotoCarousel extends StatefulWidget {
  const _PhotoCarousel({required this.urls});
  final List<String> urls;

  @override
  State<_PhotoCarousel> createState() => _PhotoCarouselState();
}

class _PhotoCarouselState extends State<_PhotoCarousel> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 220,
            child: PageView.builder(
              itemCount: widget.urls.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => Image.network(
                widget.urls[i],
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image_outlined, size: 48),
                ),
              ),
            ),
          ),
        ),
        if (widget.urls.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.urls.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _index == i ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: _index == i
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context)
                          .colorScheme
                          .outlineVariant,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Revision history sheet ─────────────────────────────────────────────────────

class _RevisionHistorySheet extends StatelessWidget {
  const _RevisionHistorySheet({
    required this.revisions,
    required this.current,
    required this.onSelect,
  });
  final List<RecipeRevision> revisions;
  final RecipeRevision? current;
  final void Function(RecipeRevision) onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('Version History',
              style: Theme.of(context).textTheme.titleMedium),
        ),
        const Divider(height: 1),
        ...revisions.map((rev) {
          final isCurrent = rev.revisionNum == (current?.revisionNum ?? -1);
          return ListTile(
            title: Text('Version ${rev.revisionNum}'),
            subtitle: Text(rev.dateCreated.isNotEmpty
                ? rev.dateCreated
                : '${rev.materials.length} ingredients'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StatusChip(status: rev.status),
                if (isCurrent)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(Icons.check_circle_outline,
                        size: 18, color: scheme.primary),
                  ),
              ],
            ),
            onTap: () => onSelect(rev),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── UMF section ───────────────────────────────────────────────────────────────

class _UmfSection extends ConsumerWidget {
  const _UmfSection({required this.ingredients});
  final List<RecipeIngredient> ingredients;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final materialsAsync = ref.watch(materialsProvider);

    return materialsAsync.when(
      loading: () => const SizedBox(
          height: 48, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
      data: (materials) {
        final result = calculateUmf(ingredients, materials);
        if (result == null) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('UMF Chemistry',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _UmfTable(result: result),
            const SizedBox(height: 20),
            Text('Stull Chart',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            _StullChart(si: result.si, al: result.al),
          ],
        );
      },
    );
  }
}

// ── UMF table ─────────────────────────────────────────────────────────────────

class _UmfTable extends StatelessWidget {
  const _UmfTable({required this.result});
  final UmfResult result;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rows   = <Widget>[];
    var  first   = true;

    for (final group in umfDisplayGroups) {
      final groupRows = group
          .where((ox) =>
              result.oxides.containsKey(ox) && result.oxides[ox]! > 0.001)
          .toList();
      if (groupRows.isEmpty) continue;

      if (!first) {
        rows.add(const Divider(height: 8));
      }
      first = false;

      for (final ox in groupRows) {
        final val = result.oxides[ox]!;
        rows.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              SizedBox(
                width: 72,
                child: Text(ox,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: (val / 5.0).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: scheme.surfaceContainerHighest,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 48,
                child: Text(val.toStringAsFixed(3),
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            ],
          ),
        ));
      }
    }

    if (rows.isEmpty) {
      return const Text('Could not calculate UMF — some materials not found.',
          style: TextStyle(color: Colors.grey));
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: rows,
      ),
    );
  }
}

// ── Stull chart ───────────────────────────────────────────────────────────────

class _StullChart extends StatelessWidget {
  const _StullChart({required this.si, required this.al});
  final double si;
  final double al;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        height: 180,
        child: CustomPaint(
          painter: _StullPainter(
            si: si,
            al: al,
            textColor: scheme.onSurface,
            pointColor: scheme.error,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _StullPainter extends CustomPainter {
  const _StullPainter({
    required this.si,
    required this.al,
    required this.textColor,
    required this.pointColor,
  });
  final double si;
  final double al;
  final Color textColor;
  final Color pointColor;

  // Chart ranges
  static const _maxSi = 7.0;
  static const _maxAl = 0.8;
  static const _leftPad  = 36.0;
  static const _botPad   = 24.0;
  static const _topPad   = 8.0;
  static const _rightPad = 8.0;

  double _x(double si, double w) =>
      _leftPad + (si / _maxSi) * (w - _leftPad - _rightPad);
  double _y(double al, double h) =>
      _topPad + (1 - al / _maxAl) * (h - _topPad - _botPad);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final chartW = w - _leftPad - _rightPad;
    final chartH = h - _topPad - _botPad;

    // ── Zone backgrounds ────────────────────────────────────────────────
    // Matte boundary: Al = 0.75 - 0.1*Si (above = matte/underfired)
    // Underfired: Si < 2
    // Running: Al < 0.2

    // Draw glossy zone (Si>2, 0.2<Al, below matte line)
    final glossyPath = Path();
    glossyPath.moveTo(_x(2, w), _y(0.2, h));
    for (double s = 2; s <= _maxSi; s += 0.25) {
      final matteAl = (0.75 - 0.1 * s).clamp(0.0, _maxAl);
      glossyPath.lineTo(_x(s, w), _y(matteAl, h));
    }
    glossyPath.lineTo(_x(_maxSi, w), _y(0.2, h));
    glossyPath.close();
    canvas.drawPath(
        glossyPath, Paint()..color = Colors.green.withAlpha(35));

    // Matte zone (Si>2, above glossy line, Al<maxAl)
    final mattePath = Path();
    mattePath.moveTo(_x(2, w), _topPad);
    for (double s = 2; s <= _maxSi; s += 0.25) {
      final matteAl = (0.75 - 0.1 * s).clamp(0.0, _maxAl);
      mattePath.lineTo(_x(s, w), _y(matteAl, h));
    }
    mattePath.lineTo(_x(_maxSi, w), _topPad);
    mattePath.close();
    canvas.drawPath(
        mattePath, Paint()..color = Colors.orange.withAlpha(45));

    // Underfired zone (Si < 2)
    canvas.drawRect(
        Rect.fromLTRB(_leftPad, _topPad, _x(2, w), h - _botPad),
        Paint()..color = Colors.red.withAlpha(30));

    // Running zone (Al < 0.2, Si > 2)
    canvas.drawRect(
        Rect.fromLTRB(_x(2, w), _y(0.2, h), w - _rightPad, h - _botPad),
        Paint()..color = Colors.blue.withAlpha(25));

    // ── Grid lines ────────────────────────────────────────────────────────
    final gridPaint = Paint()
      ..color = textColor.withAlpha(30)
      ..strokeWidth = 0.5;
    for (int s = 1; s <= 6; s++) {
      canvas.drawLine(
          Offset(_x(s.toDouble(), w), _topPad),
          Offset(_x(s.toDouble(), w), h - _botPad),
          gridPaint);
    }
    for (final al in [0.2, 0.4, 0.6]) {
      canvas.drawLine(
          Offset(_leftPad, _y(al, h)),
          Offset(w - _rightPad, _y(al, h)),
          gridPaint);
    }

    // ── Axes ──────────────────────────────────────────────────────────────
    final axisPaint = Paint()
      ..color = textColor.withAlpha(100)
      ..strokeWidth = 1.0;
    canvas.drawLine(
        Offset(_leftPad, _topPad),
        Offset(_leftPad, h - _botPad),
        axisPaint);
    canvas.drawLine(
        Offset(_leftPad, h - _botPad),
        Offset(w - _rightPad, h - _botPad),
        axisPaint);

    // ── Labels ────────────────────────────────────────────────────────────
    final tp = TextPainter(textDirection: TextDirection.ltr);
    final labelStyle = TextStyle(
        color: textColor.withAlpha(160), fontSize: 9);

    // X axis labels (Si)
    for (int s = 0; s <= 6; s += 2) {
      tp.text = TextSpan(text: '$s', style: labelStyle);
      tp.layout();
      tp.paint(canvas,
          Offset(_x(s.toDouble(), w) - tp.width / 2, h - _botPad + 4));
    }
    // X axis title
    tp.text = TextSpan(text: 'SiO₂', style: labelStyle);
    tp.layout();
    tp.paint(canvas, Offset(w / 2 - tp.width / 2, h - _botPad + 14));

    // Y axis labels (Al)
    for (final al in [0.2, 0.4, 0.6]) {
      tp.text = TextSpan(text: al.toStringAsFixed(1), style: labelStyle);
      tp.layout();
      tp.paint(canvas,
          Offset(_leftPad - tp.width - 3, _y(al, h) - tp.height / 2));
    }

    // Zone labels
    final zoneStyle = TextStyle(
        color: textColor.withAlpha(100),
        fontSize: 8,
        fontStyle: FontStyle.italic);
    void zoneLabel(String text, double sx, double ay) {
      tp.text = TextSpan(text: text, style: zoneStyle);
      tp.layout();
      tp.paint(canvas, Offset(_x(sx, w), _y(ay, h)));
    }

    zoneLabel('Matte', 3.5, 0.65);
    zoneLabel('Glossy', 3.5, 0.32);
    zoneLabel('Running', 4.0, 0.12);
    zoneLabel('Underfired', 0.5, 0.45);

    // ── Glaze point ───────────────────────────────────────────────────────
    final siClamped = si.clamp(0.0, _maxSi);
    final alClamped = al.clamp(0.0, _maxAl);
    final px = _x(siClamped, w);
    final py = _y(alClamped, h);

    canvas.drawCircle(
        Offset(px, py),
        5,
        Paint()
          ..color = pointColor
          ..style = PaintingStyle.fill);
    canvas.drawCircle(
        Offset(px, py),
        5,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    // Label for the point
    tp.text = TextSpan(
        text: '(${si.toStringAsFixed(2)}, ${al.toStringAsFixed(3)})',
        style: TextStyle(
            color: pointColor.withAlpha(200),
            fontSize: 9,
            fontWeight: FontWeight.w600));
    tp.layout();
    final labelX = (px + 8).clamp(0.0, w - tp.width - _rightPad);
    final labelY = (py - tp.height - 2).clamp(_topPad, h - _botPad);
    tp.paint(canvas, Offset(labelX, labelY));
  }

  @override
  bool shouldRepaint(_StullPainter old) =>
      old.si != si || old.al != al;
}

// ── Ingredient row ────────────────────────────────────────────────────────────

class _IngredientRow extends StatelessWidget {
  const _IngredientRow(
      {required this.ingredient, required this.totalPct});
  final RecipeIngredient ingredient;
  final double totalPct;

  @override
  Widget build(BuildContext context) {
    final fraction =
        totalPct > 0 ? ingredient.percentage / totalPct : 0.0;
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

// ── Chip widgets ──────────────────────────────────────────────────────────────

class _ConeChip extends StatelessWidget {
  const _ConeChip({required this.cone});
  final String cone;

  @override
  Widget build(BuildContext context) => Chip(
        avatar: const Icon(Icons.change_history, size: 14),
        label: Text(cone, style: const TextStyle(fontSize: 12)),
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) => Chip(
        label: Text(status, style: const TextStyle(fontSize: 12)),
        backgroundColor: _statusColor(status).withAlpha(35),
        side: BorderSide(color: _statusColor(status).withAlpha(140)),
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      );
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
