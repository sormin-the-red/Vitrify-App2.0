import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_notifier.dart';
import 'auth_state.dart';

/// Wraps a screen that requires authentication.
/// Shows an inline sign-in prompt instead of redirecting away.
/// After login the auth state change causes this widget to rebuild and show [child].
class AuthGate extends ConsumerWidget {
  final Widget child;

  const AuthGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);

    return switch (auth) {
      AuthLoading() => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      AuthAuthenticated() => child,
      AuthUnauthenticated() => _SignInPlaceholder(
          returnPath: GoRouterState.of(context).matchedLocation,
        ),
    };
  }
}

class _SignInPlaceholder extends StatelessWidget {
  final String returnPath;

  const _SignInPlaceholder({required this.returnPath});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final encoded = Uri.encodeComponent(returnPath);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 72,
                  color: theme.colorScheme.primary.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 24),
                Text(
                  'Sign in to continue',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create an account or sign in to access this feature.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () => context.push('/login?from=$encoded'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text('Sign In'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => context.push('/register?from=$encoded'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text('Create Account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
