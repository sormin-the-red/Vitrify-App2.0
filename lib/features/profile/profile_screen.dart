import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_notifier.dart';
import '../../core/auth/auth_state.dart';

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
          CircleAvatar(
            radius: 48,
            child: Text(
              user?.username.substring(0, 1).toUpperCase() ?? '?',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.username ?? '',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 32),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.star_outline),
            title: const Text('GlazeVault Premium'),
            subtitle: const Text('Unlimited AI recipe generation'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
            title: Text('Sign Out',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
            onTap: () async {
              await ref.read(authNotifierProvider.notifier).signOut();
            },
          ),
        ],
      ),
    );
  }
}
