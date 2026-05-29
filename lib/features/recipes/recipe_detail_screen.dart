import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart' show statusColor, kColorPass, kColorFail, kColorTesting;
import '../../core/auth/auth_notifier.dart';
import '../../core/auth/auth_state.dart';
import '../../core/chemistry/umf_calculator.dart';
import '../../core/materials/materials_repository.dart';
import '../mixes/mix_models.dart';
import '../mixes/mix_setup_sheet.dart';
import '../mixes/mixes_repository.dart';
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
          body: const Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
          appBar: AppBar(title: const Text('Recipe')),
          body: Center(child: Text('$e'))),
      data: (recipe) => _RecipeView(recipe: recipe),
    );
  }
}

// ── Recipe view (stateful so revision selection and scaling can be tracked) ───

class _RecipeView extends ConsumerStatefulWidget {
  const _RecipeView({required this.recipe});
  final RecipeDetail recipe;

  @override
  ConsumerState<_RecipeView> createState() => _RecipeViewState();
}

class _RecipeViewState extends ConsumerState<_RecipeView> {
  RecipeRevision? _selectedRevision;
  bool _showScaling = false;
  final _scaleCtrl = TextEditingController();

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_RecipeView old) {
    super.didUpdateWidget(old);
    if (widget.recipe.dateModified != old.recipe.dateModified) {
      _selectedRevision = null;
    }
  }

  RecipeRevision? get _revision =>
      _selectedRevision ?? widget.recipe.revision;

  double? get _batchGrams => double.tryParse(_scaleCtrl.text);

  void _showMixSetup() {
    final revision = _revision;
    if (revision == null || revision.materials.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add ingredients before mixing.')));
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) =>
          MixSetupSheet(recipe: widget.recipe, revision: revision),
    );
  }

  void _openEditor(RecipeRevision? targetRevision) {
    final recipe = widget.recipe;
    final editTarget = (targetRevision != null && targetRevision != recipe.revision)
        ? recipe.copyWith(revision: targetRevision)
        : recipe;
    context.push('/recipe/${recipe.id}/edit', extra: editTarget);
  }

  void _showRevisionHistory() {
    // Use embedded revisions if available, otherwise load them inside the sheet.
    final embedded = widget.recipe.revisions;
    final future = embedded.isNotEmpty
        ? null
        : ref.read(recipeRevisionsProvider(widget.recipe.id).future);

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
        latestRevisionNum: widget.recipe.revisionCount,
        onSelect: (rev) {
          setState(() => _selectedRevision = rev);
          Navigator.pop(ctx);
        },
        onEdit: isOwner
            ? (rev) {
                Navigator.pop(ctx);
                _openEditor(rev);
              }
            : null,
        onDelete: isOwner ? _deleteLatestRevision : null,
      ),
    );
  }

  Future<void> _deleteLatestRevision(RecipeRevision rev) async {
    try {
      await ref.read(recipesRepositoryProvider).deleteRevision(widget.recipe.id, rev.revisionNum);
      ref.invalidate(recipeDetailProvider(widget.recipe.id));
      ref.invalidate(recipeRevisionsProvider(widget.recipe.id));
      ref.invalidate(recipesListProvider);
      if (mounted) setState(() => _selectedRevision = null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _duplicateRecipe() async {
    final recipe = widget.recipe;
    final nameCtrl = TextEditingController(text: '${recipe.name} (Copy)');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Duplicate Recipe'),
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

    final authState = ref.read(authNotifierProvider);
    final currentUid =
        authState is AuthAuthenticated ? authState.user.userId : '';
    final isOwnRecipe = recipe.uid == currentUid;

    try {
      final revision = _revision;
      final revNotes = revision?.notes ?? '';
      final notesText = revNotes.isNotEmpty ? revNotes : recipe.notes;
      final newId = await ref.read(recipesRepositoryProvider).createRecipe(
        name: pickedName.isEmpty ? '${recipe.name} (Copy)' : pickedName,
        description: recipe.description.isEmpty ? null : recipe.description,
        cone: recipe.cone.isEmpty ? null : recipe.cone,
        firingType: recipe.firingType.isEmpty ? null : recipe.firingType,
        notes: notesText.isEmpty ? null : notesText,
        isPublic: false,
        color: recipe.color,
        finish: recipe.finish.isEmpty ? null : recipe.finish,
        surface: recipe.surface.isEmpty ? null : recipe.surface,
        transparency: recipe.transparency.isEmpty ? null : recipe.transparency,
        materials: revision?.materials ?? [],
        imageUrls: revision?.imageUrls ?? [],
        status: revision?.status ?? 'New',
        duplicateOriginId: isOwnRecipe ? null : recipe.id,
        duplicateOriginName: isOwnRecipe ? null : recipe.name,
      );
      ref.invalidate(recipesListProvider);
      if (mounted) context.push('/recipe/$newId');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipe   = widget.recipe;
    final revision = _revision;
    final scheme   = Theme.of(context).colorScheme;
    final authState = ref.watch(authNotifierProvider);
    final isOwner = authState is AuthAuthenticated &&
        authState.user.userId == recipe.uid;

    final baseMaterials = revision?.materials.where((m) => !m.isAddition).toList() ?? [];
    final addMaterials  = revision?.materials.where((m) => m.isAddition).toList() ?? [];
    final basePct       = baseMaterials.fold<double>(0, (s, m) => s + m.percentage);
    final addPct        = addMaterials.fold<double>(0, (s, m) => s + m.percentage);

    final status        = revision?.status ?? recipe.status;
    final imageUrls     = (revision?.imageUrls.isNotEmpty ?? false)
        ? revision!.imageUrls
        : (recipe.imageUrl.isNotEmpty ? [recipe.imageUrl] : <String>[]);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.invalidate(recipeDetailProvider(recipe.id)),
        child: CustomScrollView(
          slivers: [
            SliverAppBar.medium(
              pinned: true,
              title: Text(recipe.name),
              actions: [
                if (isOwner)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Edit',
                    onPressed: () => _openEditor(_selectedRevision),
                  ),
                PopupMenuButton<_DetailAction>(
                  onSelected: (action) {
                    switch (action) {
                      case _DetailAction.history:   _showRevisionHistory();
                      case _DetailAction.duplicate: _duplicateRecipe();
                    }
                  },
                  itemBuilder: (_) => [
                    if (recipe.revisionCount > 1)
                      const PopupMenuItem(
                        value: _DetailAction.history,
                        child: ListTile(
                          leading: Icon(Icons.history_outlined),
                          title: Text('Version history'),
                          contentPadding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    const PopupMenuItem(
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
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList.list(
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

            // ── Duplicate origin attribution ─────────────────────────────────
            if ((recipe.duplicateOriginId ?? '').isNotEmpty)
              InkWell(
                onTap: () =>
                    context.push('/recipe/${recipe.duplicateOriginId}'),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: scheme.outlineVariant, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.content_copy_outlined,
                          size: 14, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Adapted from "${recipe.duplicateOriginName}"',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                      Icon(Icons.chevron_right,
                          size: 16, color: scheme.onSurfaceVariant),
                    ],
                  ),
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
                if (recipe.finish.isNotEmpty)
                  _MetaChip(label: recipe.finish, icon: Icons.water_drop_outlined),
                if (recipe.surface.isNotEmpty)
                  _MetaChip(label: recipe.surface, icon: Icons.texture_outlined),
                if (recipe.transparency.isNotEmpty)
                  _MetaChip(label: recipe.transparency, icon: Icons.opacity_outlined),
                ...recipe.color.map((c) => _MetaChip(label: c, icon: Icons.palette_outlined)),
                if (recipe.isPublic)
                  _MetaChip(label: 'Public', icon: Icons.public),
                if (recipe.revisionCount > 1)
                  ActionChip(
                    avatar: const Icon(Icons.history, size: 14),
                    label: Text(
                        'v${revision?.revisionNum ?? recipe.revisionCount}',
                        style: const TextStyle(fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                    onPressed: _showRevisionHistory,
                  ),
                if (recipe.likeCount > 0)
                  _MetaChip(
                      label: '${recipe.likeCount}',
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

            // ── Base ingredients header + scaling toggle ──────────────────────
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
                          ? statusColor('Tested')
                          : statusColor('Testing'),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Scale to batch weight',
                  child: IconButton(
                    icon: Icon(
                      Icons.scale_outlined,
                      size: 20,
                      color: _showScaling ? scheme.primary : null,
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed: () =>
                        setState(() => _showScaling = !_showScaling),
                  ),
                ),
              ],
            ),

            // ── Batch weight input ────────────────────────────────────────────
            if (_showScaling) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _scaleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Batch weight',
                  suffixText: 'g',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 4),
            ],
            const SizedBox(height: 8),

            if (baseMaterials.isEmpty)
              const Text('No ingredients.',
                  style: TextStyle(color: Colors.grey))
            else
              ...baseMaterials.map((m) => _IngredientRow(
                    ingredient: m,
                    totalPct: basePct,
                    batchGrams: _batchGrams != null && basePct > 0
                        ? _batchGrams! * m.percentage / 100.0
                        : null,
                  )),

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
              ...addMaterials.map((m) => _IngredientRow(
                    ingredient: m,
                    totalPct: addPct,
                    batchGrams: _batchGrams != null && addPct > 0
                        ? _batchGrams! * m.percentage / 100.0
                        : null,
                  )),
            ],

            // ── Notes ─────────────────────────────────────────────────────────
            Builder(builder: (context) {
              final notesText = (revision != null && revision.notes.isNotEmpty)
                  ? revision.notes
                  : recipe.notes;
              if (notesText.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Text('Notes', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(notesText),
                ],
              );
            }),

            // ── Mix Glaze ─────────────────────────────────────────────────────
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.scale_outlined, size: 18),
                label: const Text('Mix Glaze'),
                onPressed: baseMaterials.isEmpty ? null : _showMixSetup,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            // ── Mix history ───────────────────────────────────────────────────
            const SizedBox(height: 20),
            _MixHistory(
              recipeId: recipe.id,
              revisionNum: revision?.revisionNum ?? recipe.revisionCount,
            ),

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
          ],
        ),
      ),
    );
  }
}

enum _DetailAction { history, duplicate }

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
              itemBuilder: (context, i) => GestureDetector(
                onTap: () => showDialog<void>(
                  context: context,
                  barrierColor: Colors.black87,
                  barrierDismissible: true,
                  builder: (_) => Dialog.fullscreen(
                    backgroundColor: Colors.transparent,
                    child: _FullScreenGallery(
                      urls: widget.urls,
                      initialIndex: i,
                    ),
                  ),
                ),
                child: Image.network(
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

// ── Fullscreen image gallery ──────────────────────────────────────────────────

class _FullScreenGallery extends StatefulWidget {
  const _FullScreenGallery({required this.urls, required this.initialIndex});
  final List<String> urls;
  final int initialIndex;

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late final PageController _ctrl;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          controller: _ctrl,
          itemCount: widget.urls.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (context, i) => InteractiveViewer(
            minScale: 0.8,
            maxScale: 4.0,
            child: Center(
              child: Image.network(
                widget.urls[i],
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.broken_image_outlined,
                  size: 64,
                  color: Colors.white54,
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black45,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
        if (widget.urls.length > 1)
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_index + 1} / ${widget.urls.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Revision history sheet ─────────────────────────────────────────────────────

class _RevisionHistorySheet extends StatefulWidget {
  const _RevisionHistorySheet({
    required this.embedded,
    required this.future,
    required this.current,
    required this.latestRevisionNum,
    required this.onSelect,
    this.onEdit,
    this.onDelete,
  });
  final List<RecipeRevision> embedded;
  final Future<List<RecipeRevision>>? future;
  final RecipeRevision? current;
  final int latestRevisionNum;
  final void Function(RecipeRevision) onSelect;
  final void Function(RecipeRevision)? onEdit;
  final void Function(RecipeRevision)? onDelete;

  @override
  State<_RevisionHistorySheet> createState() => _RevisionHistorySheetState();
}

class _RevisionHistorySheetState extends State<_RevisionHistorySheet> {
  List<RecipeRevision>? _revisions;
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
    }
  }

  Future<void> _confirmDelete(RecipeRevision rev) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete v${rev.revisionNum}?'),
        content: Text(
            'This can\'t be undone. The recipe will revert to v${rev.revisionNum - 1}.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    widget.onDelete?.call(rev);
    if (mounted) Navigator.pop(context);
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
      builder: (ctx) => _RecipeDiffDialog(vA: a, vB: b),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme    = Theme.of(context).colorScheme;
    final revisions = _revisions ?? [];

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, sc) => Column(
        children: [
          // Handle bar
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
                              title: Text(
                                  'Version ${rev.revisionNum}${isLatest ? "  (latest)" : ""}'),
                              subtitle: Text(rev.dateCreated.isNotEmpty
                                  ? rev.dateCreated
                                  : '${rev.materials.length} ingredients  •  ${rev.status}'),
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
                                      : const Icon(
                                          Icons.radio_button_unchecked,
                                          size: 20,
                                          color: Colors.grey)),
                              trailing: _compareMode
                                  ? null
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _StatusChip(status: rev.status),
                                        if (widget.onEdit != null)
                                          IconButton(
                                            icon: const Icon(
                                                Icons.edit_outlined,
                                                size: 18),
                                            tooltip: 'Edit this version',
                                            onPressed: () =>
                                                widget.onEdit!(rev),
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                        if (widget.onDelete != null &&
                                            isLatest &&
                                            widget.latestRevisionNum > 1)
                                          IconButton(
                                            icon: Icon(
                                                Icons.delete_outline,
                                                size: 18,
                                                color: Colors.red.shade300),
                                            tooltip: 'Delete this revision',
                                            onPressed: () =>
                                                _confirmDelete(rev),
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                      ],
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

// ── Recipe diff dialog ────────────────────────────────────────────────────────

class _RecipeDiffDialog extends StatelessWidget {
  const _RecipeDiffDialog({required this.vA, required this.vB});
  final RecipeRevision vA;
  final RecipeRevision vB;

  @override
  Widget build(BuildContext context) {
    final aMap = {for (final m in vA.materials) m.name: m.percentage};
    final bMap = {for (final m in vB.materials) m.name: m.percentage};
    final allNames = {...aMap.keys, ...bMap.keys}.toList()..sort();

    final rows = <_DiffRow>[];
    for (final name in allNames) {
      final inA = aMap.containsKey(name);
      final inB = bMap.containsKey(name);
      if (!inA) {
        rows.add(_DiffRow(name: name, change: _Change.added, bPct: bMap[name]!));
      } else if (!inB) {
        rows.add(_DiffRow(name: name, change: _Change.removed, aPct: aMap[name]!));
      } else if ((aMap[name]! - bMap[name]!).abs() > 0.05) {
        rows.add(_DiffRow(
            name: name,
            change: _Change.changed,
            aPct: aMap[name]!,
            bPct: bMap[name]!));
      } else {
        rows.add(_DiffRow(name: name, change: _Change.same, aPct: aMap[name]!));
      }
    }

    return AlertDialog(
      title: Text('v${vA.revisionNum} vs v${vB.revisionNum}'),
      content: SizedBox(
        width: double.maxFinite,
        child: rows.isEmpty
            ? const Text('No differences found.')
            : ListView.builder(
                shrinkWrap: true,
                itemCount: rows.length,
                itemBuilder: (_, i) => _DiffRowWidget(row: rows[i]),
              ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close')),
      ],
    );
  }
}

enum _Change { added, removed, changed, same }

class _DiffRow {
  final String name;
  final _Change change;
  final double? aPct;
  final double? bPct;
  const _DiffRow({
    required this.name,
    required this.change,
    this.aPct,
    this.bPct,
  });
}

class _DiffRowWidget extends StatelessWidget {
  const _DiffRowWidget({required this.row});
  final _DiffRow row;

  @override
  Widget build(BuildContext context) {
    Color bg;
    String detail;
    switch (row.change) {
      case _Change.added:
        bg = kColorPass.withValues(alpha: 0.12);
        detail = '+${row.bPct!.toStringAsFixed(1)}%';
      case _Change.removed:
        bg = kColorFail.withValues(alpha: 0.12);
        detail = '−${row.aPct!.toStringAsFixed(1)}%';
      case _Change.changed:
        bg = kColorTesting.withValues(alpha: 0.12);
        final delta = row.bPct! - row.aPct!;
        detail = '${row.aPct!.toStringAsFixed(1)}% → ${row.bPct!.toStringAsFixed(1)}%'
            '  (${delta > 0 ? "+" : ""}${delta.toStringAsFixed(1)}%)';
      case _Change.same:
        bg = Colors.transparent;
        detail = '${row.aPct!.toStringAsFixed(1)}%';
    }
    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(row.name, style: const TextStyle(fontSize: 13))),
          Text(detail,
              style: TextStyle(
                  fontSize: 12,
                  color: row.change == _Change.same ? Colors.grey : null)),
        ],
      ),
    );
  }
}

// ── Mix history ───────────────────────────────────────────────────────────────

class _MixHistory extends ConsumerWidget {
  const _MixHistory({required this.recipeId, required this.revisionNum});
  final String recipeId;
  final int revisionNum;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recipeMixesProvider(recipeId));
    return async.when(
      loading: () => const SizedBox(
          height: 32, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
      data: (allMixes) {
        final mixes = allMixes.where((m) => m.revisionNum == revisionNum).toList();
        if (mixes.isEmpty) return const SizedBox.shrink();
        final scheme = Theme.of(context).colorScheme;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mix History',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            ...mixes.take(5).map((m) {
              final isComplete = m.status == MixStatus.complete;
              final label = _fmtBatch(m);
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: isComplete
                      ? Colors.green.shade400.withValues(alpha: 0.15)
                      : scheme.secondaryContainer,
                  child: Icon(
                    isComplete ? Icons.check : Icons.hourglass_top_outlined,
                    size: 14,
                    color: isComplete
                        ? Colors.green.shade600
                        : scheme.onSecondaryContainer,
                  ),
                ),
                title: Text(label, style: const TextStyle(fontSize: 13)),
                subtitle: Text(
                  '${m.checkedCount} / ${m.totalCount} materials'
                  '${isComplete ? " · complete" : ""}',
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: isComplete
                    ? null
                    : TextButton(
                        onPressed: () =>
                            context.push('/mix/${m.id}'),
                        style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero),
                        child: const Text('Resume'),
                      ),
              );
            }),
          ],
        );
      },
    );
  }

  String _fmtBatch(MixSummary m) {
    final v = switch (m.displayUnit) {
      'lbs' => (m.batchSizeGrams * 0.00220462).toStringAsFixed(1),
      'kg'  => (m.batchSizeGrams / 1000).toStringAsFixed(2),
      'oz'  => (m.batchSizeGrams * 0.035274).toStringAsFixed(0),
      _     => m.batchSizeGrams.toStringAsFixed(0),
    };
    final date = m.dateCreated.length >= 10 ? m.dateCreated.substring(0, 10) : m.dateCreated;
    return '$v ${m.displayUnit}  ·  $date';
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

    final glossyPath = Path();
    glossyPath.moveTo(_x(2, w), _y(0.2, h));
    for (double s = 2; s <= _maxSi; s += 0.25) {
      final matteAl = (0.75 - 0.1 * s).clamp(0.0, _maxAl);
      glossyPath.lineTo(_x(s, w), _y(matteAl, h));
    }
    glossyPath.lineTo(_x(_maxSi, w), _y(0.2, h));
    glossyPath.close();
    canvas.drawPath(glossyPath, Paint()..color = Colors.green.withAlpha(35));

    final mattePath = Path();
    mattePath.moveTo(_x(2, w), _topPad);
    for (double s = 2; s <= _maxSi; s += 0.25) {
      final matteAl = (0.75 - 0.1 * s).clamp(0.0, _maxAl);
      mattePath.lineTo(_x(s, w), _y(matteAl, h));
    }
    mattePath.lineTo(_x(_maxSi, w), _topPad);
    mattePath.close();
    canvas.drawPath(mattePath, Paint()..color = Colors.orange.withAlpha(45));

    canvas.drawRect(
        Rect.fromLTRB(_leftPad, _topPad, _x(2, w), h - _botPad),
        Paint()..color = Colors.red.withAlpha(30));

    canvas.drawRect(
        Rect.fromLTRB(_x(2, w), _y(0.2, h), w - _rightPad, h - _botPad),
        Paint()..color = Colors.blue.withAlpha(25));

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

    final axisPaint = Paint()
      ..color = textColor.withAlpha(100)
      ..strokeWidth = 1.0;
    canvas.drawLine(
        Offset(_leftPad, _topPad), Offset(_leftPad, h - _botPad), axisPaint);
    canvas.drawLine(
        Offset(_leftPad, h - _botPad),
        Offset(w - _rightPad, h - _botPad),
        axisPaint);

    final tp = TextPainter(textDirection: TextDirection.ltr);
    final labelStyle = TextStyle(color: textColor.withAlpha(160), fontSize: 9);

    for (int s = 0; s <= 6; s += 2) {
      tp.text = TextSpan(text: '$s', style: labelStyle);
      tp.layout();
      tp.paint(canvas,
          Offset(_x(s.toDouble(), w) - tp.width / 2, h - _botPad + 4));
    }
    tp.text = TextSpan(text: 'SiO₂', style: labelStyle);
    tp.layout();
    tp.paint(canvas, Offset(w / 2 - tp.width / 2, h - _botPad + 14));

    for (final al in [0.2, 0.4, 0.6]) {
      tp.text = TextSpan(text: al.toStringAsFixed(1), style: labelStyle);
      tp.layout();
      tp.paint(canvas,
          Offset(_leftPad - tp.width - 3, _y(al, h) - tp.height / 2));
    }

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

    final siClamped = si.clamp(0.0, _maxSi);
    final alClamped = al.clamp(0.0, _maxAl);
    final px = _x(siClamped, w);
    final py = _y(alClamped, h);

    canvas.drawCircle(Offset(px, py), 5,
        Paint()..color = pointColor..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(px, py), 5,
        Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);

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
  bool shouldRepaint(_StullPainter old) => old.si != si || old.al != al;
}

// ── Ingredient row ────────────────────────────────────────────────────────────

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    required this.ingredient,
    required this.totalPct,
    this.batchGrams,
  });
  final RecipeIngredient ingredient;
  final double totalPct;
  final double? batchGrams;

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
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: fraction.clamp(0.0, 1.0),
                minHeight: 12,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: batchGrams != null ? 88 : 46,
            child: batchGrams != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(pctText,
                          textAlign: TextAlign.right,
                          style: Theme.of(context).textTheme.bodySmall),
                      Text('${batchGrams!.toStringAsFixed(1)}g',
                          textAlign: TextAlign.right,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600)),
                    ],
                  )
                : Text(pctText,
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
        avatar: Icon(Icons.change_history, size: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
        label: Text('Cone $cone',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final c = statusColor(status);
    return Chip(
      label: Text(status),
      backgroundColor: c.withValues(alpha: 0.12),
      side: BorderSide(color: c.withValues(alpha: 0.4), width: 0.8),
      labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.symmetric(horizontal: 6),
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
