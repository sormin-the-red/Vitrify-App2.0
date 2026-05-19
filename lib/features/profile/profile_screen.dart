import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_notifier.dart';
import '../../core/auth/auth_state.dart';
import '../batches/batches_repository.dart';
import '../recipes/recipes_repository.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),
          // Avatar
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                user?.username.isNotEmpty == true
                    ? user!.username[0].toUpperCase()
                    : '?',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (user != null) ...[
            Text(
              user.username,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ] else
            Text(
              'Not signed in',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),

          const SizedBox(height: 24),

          // Stats row
          if (user != null) _StatsRow(),

          const SizedBox(height: 24),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings'),
          ),
          ListTile(
            leading: const Icon(Icons.star_outline),
            title: const Text('GlazeVault Premium'),
            subtitle: const Text('Unlimited AI recipe generation'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),

          const Divider(),

          if (user != null)
            ListTile(
              leading: Icon(Icons.logout,
                  color: Theme.of(context).colorScheme.error),
              title: Text('Sign Out',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error)),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Sign out?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel')),
                      FilledButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Sign Out')),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref.read(authNotifierProvider.notifier).signOut();
                }
              },
            )
          else
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Sign In'),
              onTap: () => context.push('/login'),
            ),
        ],
      ),
    );
  }
}

class _StatsRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(recipesListProvider);
    final batchesAsync = ref.watch(batchesListProvider);

    final recipeCount = recipesAsync.value?.length;
    final batchCount = batchesAsync.value?.length;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Recipes',
            count: recipeCount,
            icon: Icons.science_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Batches',
            count: batchCount,
            icon: Icons.grid_view_outlined,
          ),
        ),
        const SizedBox(width: 12),
        // Placeholder for a third stat (e.g. public items)
        Expanded(
          child: _StatCard(
            label: 'Public',
            count: recipeCount == null
                ? null
                : recipesAsync.value!.where((r) => r.isPublic).length,
            icon: Icons.public_outlined,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.label, required this.count, required this.icon});
  final String label;
  final int? count;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: scheme.primary),
          const SizedBox(height: 6),
          count == null
              ? SizedBox(
                  width: 24,
                  height: 16,
                  child: LinearProgressIndicator(
                    borderRadius: BorderRadius.circular(4),
                    color: scheme.primary,
                    backgroundColor: scheme.surfaceContainerHighest,
                  ),
                )
              : Text(
                  '$count',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 20),
                ),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
