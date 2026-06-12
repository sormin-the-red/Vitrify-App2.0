import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_notifier.dart';
import '../../core/auth/auth_state.dart';
import 'community_models.dart';
import 'community_repository.dart';

/// Public profile for another potter: header, follow button, public recipes.
class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key, required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(userProfileProvider(uid));
    return async.when(
      loading: () => Scaffold(
          appBar: AppBar(),
          body: const Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
          appBar: AppBar(),
          body: Center(
              child: Text('Could not load profile.\n$e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey)))),
      data: (profile) => _ProfileView(profile: profile),
    );
  }
}

class _ProfileView extends ConsumerWidget {
  const _ProfileView({required this.profile});
  final PublicProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final auth = ref.watch(authNotifierProvider);
    final myUid = auth is AuthAuthenticated ? auth.user.userId : '';
    final isSelf = myUid == profile.uid;

    final recipesAsync = ref.watch(userRecipesProvider(profile.uid));

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userProfileProvider(profile.uid));
          ref.invalidate(userRecipesProvider(profile.uid));
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar.medium(
              pinned: true,
              title: Text(profile.displayName.isEmpty
                  ? 'Potter'
                  : profile.displayName),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList.list(children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Avatar(profile: profile, scheme: scheme),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _Stat(
                                  label: 'Followers',
                                  value: profile.followerCount),
                              const SizedBox(width: 20),
                              _Stat(
                                  label: 'Following',
                                  value: profile.followingCount),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (!isSelf && myUid.isNotEmpty)
                            _FollowButton(targetUid: profile.uid, myUid: myUid),
                        ],
                      ),
                    ),
                  ],
                ),
                if (profile.bio.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(profile.bio,
                      style: TextStyle(color: scheme.onSurfaceVariant)),
                ],
                const SizedBox(height: 24),
                Text('Public Recipes',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                recipesAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, _) => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('Could not load recipes.',
                        style: TextStyle(color: Colors.grey)),
                  ),
                  data: (recipes) => recipes.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text('No public recipes yet.',
                              style: TextStyle(color: Colors.grey)),
                        )
                      : Column(
                          children: recipes
                              .map((r) => _RecipeCard(item: r))
                              .toList(),
                        ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.profile, required this.scheme});
  final PublicProfile profile;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final initials = profile.displayName.isEmpty
        ? '?'
        : profile.displayName
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((w) => w[0].toUpperCase())
            .join();
    return CircleAvatar(
      radius: 36,
      backgroundColor: scheme.primaryContainer,
      foregroundImage: profile.photoUrl != null &&
              profile.photoUrl!.isNotEmpty
          ? NetworkImage(profile.photoUrl!)
          : null,
      child: Text(initials,
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: scheme.onPrimaryContainer)),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$value',
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700)),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _FollowButton extends ConsumerStatefulWidget {
  const _FollowButton({required this.targetUid, required this.myUid});
  final String targetUid;
  final String myUid;

  @override
  ConsumerState<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends ConsumerState<_FollowButton> {
  bool? _following; // null = still loading initial state
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    ref
        .read(communityRepositoryProvider)
        .isFollowing(widget.myUid, widget.targetUid)
        .then((v) {
      if (mounted) setState(() => _following = v);
    }).catchError((_) {
      if (mounted) setState(() => _following = false);
    });
  }

  Future<void> _toggle() async {
    final next = !(_following ?? false);
    setState(() {
      _busy = true;
      _following = next;
    });
    try {
      final repo = ref.read(communityRepositoryProvider);
      if (next) {
        await repo.follow(widget.targetUid);
      } else {
        await repo.unfollow(widget.targetUid);
      }
      ref.invalidate(userProfileProvider(widget.targetUid));
      ref.invalidate(followingFeedProvider);
    } catch (_) {
      if (mounted) setState(() => _following = !next); // revert
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final following = _following;
    if (following == null) {
      return const SizedBox(
          height: 36,
          width: 110,
          child: Center(
              child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))));
    }
    return following
        ? OutlinedButton.icon(
            onPressed: _busy ? null : _toggle,
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Following'),
            style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact),
          )
        : FilledButton.icon(
            onPressed: _busy ? null : _toggle,
            icon: const Icon(Icons.person_add_alt, size: 16),
            label: const Text('Follow'),
            style:
                FilledButton.styleFrom(visualDensity: VisualDensity.compact),
          );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.item});
  final FeedItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: () => context.push('/recipe/${item.id}'),
        leading: item.imageUrl != null && item.imageUrl!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(item.imageUrl!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Icon(
                        Icons.science_outlined,
                        color: scheme.onSurfaceVariant)),
              )
            : CircleAvatar(
                backgroundColor: scheme.surfaceContainerHighest,
                child: Icon(Icons.science_outlined,
                    size: 18, color: scheme.onSurfaceVariant)),
        title: Text(item.name,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          [
            if (item.cone != null && item.cone!.isNotEmpty) 'C${item.cone}',
            if (item.finish != null && item.finish!.isNotEmpty) item.finish!,
            ...item.color,
          ].join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite,
                size: 14, color: scheme.onSurfaceVariant),
            const SizedBox(width: 3),
            Text('${item.likeCount}',
                style: TextStyle(
                    fontSize: 12, color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
