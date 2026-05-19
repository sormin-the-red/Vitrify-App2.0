import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/materials/material_model.dart';
import '../../core/materials/materials_repository.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.push('/profile'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Materials'),
            Tab(text: 'Learn'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _MaterialsTab(),
          _LearnTab(),
        ],
      ),
    );
  }
}

// ── Materials tab ──────────────────────────────────────────────────────────────

class _MaterialsTab extends ConsumerStatefulWidget {
  const _MaterialsTab();

  @override
  ConsumerState<_MaterialsTab> createState() => _MaterialsTabState();
}

class _MaterialsTabState extends ConsumerState<_MaterialsTab> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(materialsProvider);
    return async.when(
      loading: () => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Loading materials database…',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Failed to load materials.',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () => ref.invalidate(materialsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (materials) {
        final filtered = _query.isEmpty
            ? materials
            : materials
                .where((m) =>
                    m.name.toLowerCase().contains(_query.toLowerCase()))
                .toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: SearchBar(
                controller: _searchCtrl,
                hintText: 'Search ${materials.length} materials…',
                leading: const Icon(Icons.search),
                trailing: [
                  if (_query.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    ),
                ],
                onChanged: (v) => setState(() => _query = v),
                padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 12)),
              ),
            ),
            if (filtered.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('No materials match your search.',
                      style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) =>
                      _MaterialListTile(material: filtered[i]),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MaterialListTile extends StatelessWidget {
  const _MaterialListTile({required this.material});
  final MaterialModel material;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: material.hazardous
            ? Theme.of(context).colorScheme.errorContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        radius: 18,
        child: Icon(
          material.hazardous ? Icons.warning_amber : Icons.science_outlined,
          size: 16,
          color: material.hazardous
              ? Theme.of(context).colorScheme.onErrorContainer
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      title: Text(material.name),
      subtitle: Text(
        '${material.oxides.length} oxides · MW ${material.oxidesWeight.toStringAsFixed(2)}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: () => _showDetail(context, material),
    );
  }

  void _showDetail(BuildContext context, MaterialModel material) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _MaterialDetailSheet(material: material),
    );
  }
}

class _MaterialDetailSheet extends StatelessWidget {
  const _MaterialDetailSheet({required this.material});
  final MaterialModel material;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sorted = [...material.oxides]
      ..sort((a, b) => b.analysis.compareTo(a.analysis));

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollCtrl) => ListView(
        controller: scrollCtrl,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(material.name,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            children: [
              if (material.hazardous)
                Chip(
                  avatar: Icon(Icons.warning_amber,
                      size: 14, color: scheme.onErrorContainer),
                  label: const Text('Hazardous'),
                  backgroundColor: scheme.errorContainer,
                  labelStyle: TextStyle(
                      fontSize: 11, color: scheme.onErrorContainer),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  labelPadding:
                      const EdgeInsets.symmetric(horizontal: 4),
                ),
              Chip(
                label: Text(
                    'MW ${material.oxidesWeight.toStringAsFixed(2)}'),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                labelPadding:
                    const EdgeInsets.symmetric(horizontal: 6),
                labelStyle: const TextStyle(fontSize: 11),
              ),
            ],
          ),
          if (material.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(material.description,
                style: TextStyle(color: scheme.onSurfaceVariant)),
          ],
          const SizedBox(height: 20),
          Text('Oxide Analysis',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          // Header
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Text('Oxide',
                        style: Theme.of(context).textTheme.labelSmall)),
                Expanded(
                    flex: 2,
                    child: Text('%',
                        textAlign: TextAlign.end,
                        style:
                            Theme.of(context).textTheme.labelSmall)),
                const SizedBox(width: 8),
                const SizedBox(width: 80),
              ],
            ),
          ),
          const Divider(height: 1),
          ...sorted.map((oxide) => _OxideRow(oxide: oxide)),
        ],
      ),
    );
  }
}

class _OxideRow extends StatelessWidget {
  const _OxideRow({required this.oxide});
  final OxideAnalysis oxide;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(oxide.oxideName,
                style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${oxide.analysis.toStringAsFixed(2)}%',
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: LinearProgressIndicator(
              value: (oxide.analysis / 100).clamp(0.0, 1.0),
              minHeight: 5,
              borderRadius: BorderRadius.circular(2),
              color: scheme.primary,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Learn tab ──────────────────────────────────────────────────────────────────

class _LearnTab extends StatelessWidget {
  const _LearnTab();

  static const _articles = [
    _Article(
      title: 'UMF: Unity Molecular Formula',
      icon: Icons.calculate_outlined,
      body:
          'UMF is a way of expressing glaze chemistry that normalizes the flux oxides to sum to 1. '
          'This lets you compare glazes regardless of batch size or recipe totals.\n\n'
          'Fluxes (Na₂O, K₂O, CaO, MgO, etc.) are normalized to 1.0. '
          'Alumina (Al₂O₃) and silica (SiO₂) are expressed relative to that. '
          'A balanced cone 6 glaze typically has 0.2–0.35 Al₂O₃ and 2.5–3.5 SiO₂.',
    ),
    _Article(
      title: 'Cone & Temperature',
      icon: Icons.thermostat_outlined,
      body:
          'Orton cones measure heat-work — the combination of temperature and time. '
          'The same peak temperature held longer equals a higher effective cone.\n\n'
          'Cone 6 electric: ~2232°F / 1222°C. Cone 10 reduction: ~2345°F / 1285°C. '
          'Low-fire (022–1): <1900°F. Mid-fire (4–7): 2200–2300°F. High-fire (8–14): 2300°F+.',
    ),
    _Article(
      title: 'Glaze Opacity',
      icon: Icons.opacity_outlined,
      body:
          'Opacity in glazes is caused by particles that scatter light — either bubbles, '
          'crystals, or opacifier particles. Tin oxide and zircopax are classic opacifiers, '
          'typically used at 8–12%.\n\n'
          'Titanium dioxide creates a matte, variegated opacity. '
          'Zinc oxide promotes crystal growth in certain glaze chemistries.',
    ),
    _Article(
      title: 'Firing Atmospheres',
      icon: Icons.local_fire_department_outlined,
      body:
          'Oxidation firing (electric kilns, gas with full air) keeps iron in Fe³⁺ state, '
          'producing reds, oranges, and clear colors.\n\n'
          'Reduction firing (gas/wood with limited air) converts Fe³⁺ to Fe²⁺, '
          'producing celadons, tenmoku, and carbon-trapped shinos. '
          'Copper in reduction gives red; in oxidation it gives green.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      itemCount: _articles.length,
      itemBuilder: (ctx, i) => _ArticleCard(article: _articles[i]),
    );
  }
}

class _Article {
  const _Article(
      {required this.title, required this.icon, required this.body});
  final String title;
  final IconData icon;
  final String body;
}

class _ArticleCard extends StatefulWidget {
  const _ArticleCard({required this.article});
  final _Article article;

  @override
  State<_ArticleCard> createState() => _ArticleCardState();
}

class _ArticleCardState extends State<_ArticleCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(widget.article.icon,
                      size: 20, color: scheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(widget.article.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                  Icon(
                    _expanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 12),
                Text(widget.article.body,
                    style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                        height: 1.5)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
