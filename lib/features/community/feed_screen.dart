import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_notifier.dart';
import '../../core/auth/auth_state.dart';
import 'community_models.dart';
import 'community_repository.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        title: const Text('GlazeVault'),
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
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'New'),
            Tab(text: 'Popular'),
            Tab(text: 'Schedules'),
            Tab(text: 'Following'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _GlobalFeedTab(filterKey: 'new:all'),
          _GlobalFeedTab(filterKey: 'popular:all'),
          _GlobalFeedTab(filterKey: 'new:schedules'),
          _FollowingTab(),
        ],
      ),
    );
  }
}

// ── Global feed tab ────────────────────────────────────────────────────────────

class _GlobalFeedTab extends ConsumerStatefulWidget {
  const _GlobalFeedTab({required this.filterKey});
  final String filterKey;

  @override
  ConsumerState<_GlobalFeedTab> createState() => _GlobalFeedTabState();
}

class _GlobalFeedTabState extends ConsumerState<_GlobalFeedTab> {
  // Pages after the first, accumulated by load-more. The first page lives in
  // the provider so pull-to-refresh invalidation resets everything.
  final List<FeedItem> _extraItems = [];
  String? _cursor;
  bool _cursorFromFirstPage = false;
  bool _loadingMore = false;

  Future<void> _loadMore() async {
    final cursor = _cursor;
    if (cursor == null || _loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final parts = widget.filterKey.split(':');
      final page = await ref.read(communityRepositoryProvider).getGlobalFeed(
            filter: parts[0],
            type: parts.length > 1 ? parts[1] : 'all',
            cursor: cursor,
          );
      if (!mounted) return;
      setState(() {
        _extraItems.addAll(page.items);
        _cursor = page.hasMore ? page.nextCursor : null;
      });
    } catch (_) {
      // Leave the cursor in place so a later scroll retries.
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Reset accumulated pages whenever the first page reloads (refresh).
    ref.listen(globalFeedProvider(widget.filterKey), (prev, next) {
      if (next is AsyncData<FeedPage>) {
        setState(() {
          _extraItems.clear();
          _cursor = next.value.hasMore ? next.value.nextCursor : null;
          _cursorFromFirstPage = true;
        });
      }
    });

    final async = ref.watch(globalFeedProvider(widget.filterKey));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text('$e', textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () =>
                  ref.invalidate(globalFeedProvider(widget.filterKey)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (page) {
        // ref.listen misses the very first data event when the widget mounts
        // with data already available — seed the cursor here.
        if (!_cursorFromFirstPage) {
          _cursor = page.hasMore ? page.nextCursor : null;
          _cursorFromFirstPage = true;
        }
        return _FeedList(
          items: [...page.items, ..._extraItems],
          onRefresh: () async =>
              ref.invalidate(globalFeedProvider(widget.filterKey)),
          onLoadMore: _cursor != null ? _loadMore : null,
          loadingMore: _loadingMore,
        );
      },
    );
  }
}

// ── Following tab ──────────────────────────────────────────────────────────────

class _FollowingTab extends StatelessWidget {
  const _FollowingTab();

  @override
  Widget build(BuildContext context) => const _FollowingFeedContent();
}

class _FollowingFeedContent extends ConsumerWidget {
  const _FollowingFeedContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(followingFeedProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (items) {
        if (items.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_outline, size: 56, color: Colors.grey),
                SizedBox(height: 12),
                Text('No one to follow yet.',
                    style: TextStyle(color: Colors.grey)),
                SizedBox(height: 4),
                Text('Explore New or Popular to find potters.',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          );
        }
        return _FeedList(
          items: items,
          onRefresh: () async => ref.invalidate(followingFeedProvider),
        );
      },
    );
  }
}

// ── Feed list ──────────────────────────────────────────────────────────────────

class _FeedList extends StatelessWidget {
  const _FeedList({
    required this.items,
    required this.onRefresh,
    this.onLoadMore,
    this.loadingMore = false,
  });
  final List<FeedItem> items;
  final Future<void> Function() onRefresh;
  final VoidCallback? onLoadMore;
  final bool loadingMore;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(
              child: Column(
                children: [
                  Icon(Icons.auto_awesome_outlined,
                      size: 56, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Nothing here yet.',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final showFooter = onLoadMore != null || loadingMore;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (onLoadMore != null &&
              !loadingMore &&
              n.metrics.pixels >= n.metrics.maxScrollExtent - 400) {
            onLoadMore!();
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
          itemCount: items.length + (showFooter ? 1 : 0),
          itemBuilder: (ctx, i) {
            if (i >= items.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              );
            }
            return _FeedCard(item: items[i]);
          },
        ),
      ),
    );
  }
}

// ── Feed card ──────────────────────────────────────────────────────────────────

class _FeedCard extends ConsumerWidget {
  const _FeedCard({required this.item});
  final FeedItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isRecipe = item.isRecipe;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(
            isRecipe ? '/recipe/${item.id}' : '/schedule/${item.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail or icon
              _Thumbnail(item: item),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type badge + name
                    Row(
                      children: [
                        _TypeBadge(isRecipe: isRecipe, scheme: scheme),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (item.uid.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      GestureDetector(
                        onTap: () => context.push('/user/${item.uid}'),
                        child: Text(
                          'by ${item.displayName.isEmpty ? "a potter" : item.displayName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurfaceVariant),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Meta row
                    Row(
                      children: [
                        ..._metaChips(item),
                        const Spacer(),
                        _HeartButton(item: item),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _metaChips(FeedItem item) {
    final chips = <Widget>[];
    if (item.isRecipe && item.cone != null && item.cone!.isNotEmpty) {
      chips.add(_MetaChip(label: 'C${item.cone}',
          icon: Icons.local_fire_department_outlined));
    }
    if (!item.isRecipe && item.maxCone != null && item.maxCone!.isNotEmpty) {
      chips.add(_MetaChip(label: 'C${item.maxCone}',
          icon: Icons.thermostat_outlined));
    }
    if (!item.isRecipe && item.tempScale != null &&
        item.tempScale!.isNotEmpty) {
      chips.add(_MetaChip(label: '°${item.tempScale}',
          icon: Icons.device_thermostat));
    }
    if (item.isRecipe && item.firingType != null &&
        item.firingType!.isNotEmpty) {
      chips.add(_MetaChip(label: item.firingType!, icon: null));
    }
    if (item.isRecipe && item.finish != null && item.finish!.isNotEmpty) {
      chips.add(_MetaChip(label: item.finish!, icon: null));
    }
    if (item.isRecipe && item.surface != null && item.surface!.isNotEmpty) {
      chips.add(_MetaChip(label: item.surface!, icon: null));
    }
    for (final c in item.color) {
      chips.add(_MetaChip(label: c, icon: null));
    }
    return chips;
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.item});
  final FeedItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          item.imageUrl!,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _PlaceholderIcon(
              isRecipe: item.isRecipe, scheme: scheme),
        ),
      );
    }
    return _PlaceholderIcon(isRecipe: item.isRecipe, scheme: scheme);
  }
}

class _PlaceholderIcon extends StatelessWidget {
  const _PlaceholderIcon({required this.isRecipe, required this.scheme});
  final bool isRecipe;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        isRecipe ? Icons.science_outlined : Icons.local_fire_department_outlined,
        size: 28,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.isRecipe, required this.scheme});
  final bool isRecipe;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: isRecipe
            ? scheme.primaryContainer
            : scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isRecipe ? 'Recipe' : 'Schedule',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isRecipe
              ? scheme.onPrimaryContainer
              : scheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.icon});
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 2),
          ],
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color:
                      Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

// ── Heart button (optimistic) ──────────────────────────────────────────────────

class _HeartButton extends ConsumerStatefulWidget {
  const _HeartButton({required this.item});
  final FeedItem item;

  @override
  ConsumerState<_HeartButton> createState() => _HeartButtonState();
}

class _HeartButtonState extends ConsumerState<_HeartButton> {
  late int _count;
  bool _hearted = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _count = widget.item.likeCount;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: _busy ? null : _toggle,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _hearted ? Icons.favorite : Icons.favorite_border,
            size: 16,
            color: _hearted ? scheme.error : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 3),
          Text(
            '$_count',
            style: TextStyle(
                fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Future<void> _toggle() async {
    final auth = ref.read(authNotifierProvider);
    if (auth is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to like items')),
      );
      return;
    }

    setState(() {
      _busy = true;
      _hearted = !_hearted;
      _count += _hearted ? 1 : -1;
    });

    try {
      final repo = ref.read(communityRepositoryProvider);
      if (_hearted) {
        await repo.heart(widget.item);
      } else {
        await repo.unheart(widget.item);
      }
    } catch (_) {
      // Revert on failure
      if (mounted) {
        setState(() {
          _hearted = !_hearted;
          _count += _hearted ? 1 : -1;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
