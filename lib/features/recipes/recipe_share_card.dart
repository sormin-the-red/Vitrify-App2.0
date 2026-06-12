import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/chemistry/umf_calculator.dart';
import '../../core/materials/material_model.dart';
import '../../core/materials/materials_repository.dart';
import '../../core/platform/web_utils.dart';
import 'recipe_models.dart';

/// Opens the share-card preview dialog for [recipe] at [revision].
Future<void> showRecipeShareDialog(
  BuildContext context, {
  required RecipeDetail recipe,
  required RecipeRevision? revision,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _ShareCardDialog(recipe: recipe, revision: revision),
  );
}

class _ShareCardDialog extends ConsumerStatefulWidget {
  const _ShareCardDialog({required this.recipe, required this.revision});
  final RecipeDetail recipe;
  final RecipeRevision? revision;

  @override
  ConsumerState<_ShareCardDialog> createState() => _ShareCardDialogState();
}

class _ShareCardDialogState extends ConsumerState<_ShareCardDialog> {
  final GlobalKey _cardKey = GlobalKey();
  bool _busy = false;

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final boundary = _cardKey.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final slug = widget.recipe.name
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'^-+|-+$'), '');
      final filename = '${slug.isEmpty ? 'recipe' : slug}.png';

      if (kIsWeb) {
        downloadBytes(filename, bytes);
      } else {
        await Share.shareXFiles(
          [XFile.fromData(bytes, mimeType: 'image/png', name: filename)],
          subject: widget.recipe.name,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Share failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: RepaintBoundary(
                  key: _cardKey,
                  child: _RecipeShareCard(
                    recipe: widget.recipe,
                    revision: widget.revision,
                    materialsAsync: ref.watch(materialsProvider),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _busy ? null : _share,
                    icon: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child:
                                CircularProgressIndicator(strokeWidth: 2))
                        : Icon(kIsWeb
                            ? Icons.download_outlined
                            : Icons.share_outlined),
                    label: Text(kIsWeb ? 'Download' : 'Share'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The card itself — rendered with a forced light palette so the shared
/// image is print-friendly regardless of the app theme.
class _RecipeShareCard extends StatelessWidget {
  const _RecipeShareCard({
    required this.recipe,
    required this.revision,
    required this.materialsAsync,
  });

  final RecipeDetail recipe;
  final RecipeRevision? revision;
  final AsyncValue<List<MaterialModel>> materialsAsync;

  static final _scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF9C4A22), brightness: Brightness.light);

  @override
  Widget build(BuildContext context) {
    final materials = revision?.materials ?? [];
    final base = materials.where((m) => !m.isAddition).toList();
    final additions = materials.where((m) => m.isAddition).toList();
    final basePct = base.fold<double>(0, (s, m) => s + m.percentage);

    UmfResult? umf;
    final db = materialsAsync.valueOrNull;
    if (db != null && materials.isNotEmpty) {
      umf = calculateUmf(materials, db);
    }

    final attrs = [
      if (recipe.finish.isNotEmpty) recipe.finish,
      if (recipe.surface.isNotEmpty) recipe.surface,
      if (recipe.transparency.isNotEmpty) recipe.transparency,
      ...recipe.color,
    ];

    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: 380,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            recipe.name,
            style: textTheme.headlineSmall
                ?.copyWith(color: _scheme.onSurface),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (recipe.cone.isNotEmpty)
                _pill('▲ Cone ${recipe.cone}', filled: true),
              if (recipe.firingType.isNotEmpty)
                _pill(recipe.firingType, filled: true),
              ...attrs.map(_pill),
            ],
          ),
          const SizedBox(height: 18),
          if (base.isNotEmpty) ...[
            _sectionLabel('BASE RECIPE'),
            const SizedBox(height: 6),
            ...base.map(_ingredientRow),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Divider(color: _scheme.outlineVariant, height: 8),
                  ),
                ],
              ),
            ),
            _row('Total', basePct, bold: true),
          ],
          if (additions.isNotEmpty) ...[
            const SizedBox(height: 14),
            _sectionLabel('ADDITIONS'),
            const SizedBox(height: 6),
            ...additions.map((m) => _ingredientRow(m, prefix: '+ ')),
          ],
          if (umf != null) ...[
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'UMF  ·  Si ${umf.si.toStringAsFixed(2)}'
                '  ·  Al ${umf.al.toStringAsFixed(2)}'
                '${umf.al > 0 ? '  ·  Si:Al ${umf.siAl.toStringAsFixed(1)}' : ''}',
                style: TextStyle(
                  fontSize: 11,
                  color: _scheme.onSurfaceVariant,
                  fontFeatures: const [ui.FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Icon(Icons.local_fire_department,
                  size: 14, color: _scheme.primary),
              const SizedBox(width: 4),
              Text(
                'Vitrify',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _scheme.primary,
                ),
              ),
              const Spacer(),
              if (revision != null)
                Text(
                  'v${revision!.revisionNum}',
                  style: TextStyle(
                      fontSize: 11, color: _scheme.onSurfaceVariant),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, {bool filled = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? _scheme.primaryContainer : null,
        border:
            filled ? null : Border.all(color: _scheme.outlineVariant),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: filled
              ? _scheme.onPrimaryContainer
              : _scheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: TextStyle(
          fontSize: 10,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
          color: _scheme.primary,
        ),
      );

  Widget _ingredientRow(RecipeIngredient m, {String prefix = ''}) =>
      _row('$prefix${m.name}', m.percentage);

  Widget _row(String name, double pct, {bool bold = false}) {
    final style = TextStyle(
      fontSize: 13,
      height: 1.6,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      color: _scheme.onSurface,
      fontFeatures: const [ui.FontFeature.tabularFigures()],
    );
    return Row(
      children: [
        Expanded(child: Text(name, style: style)),
        Text(pct.toStringAsFixed(pct == pct.roundToDouble() ? 0 : 1),
            style: style),
      ],
    );
  }
}
