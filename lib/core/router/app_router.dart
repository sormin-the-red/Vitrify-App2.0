import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../auth/auth_notifier.dart';
import '../auth/auth_state.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/confirm_screen.dart';
import '../../features/shell/shell_screen.dart';
import '../../features/recipes/recipes_screen.dart';
import '../../features/community/feed_screen.dart';
import '../../features/batches/batches_screen.dart';
import '../../features/inventory/inventory_screen.dart';
import '../../features/library/library_screen.dart';
import '../../features/profile/profile_screen.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(AppRouterRef ref) {
  // Bridge Riverpod state to go_router's ChangeNotifier refresh mechanism
  final authListenable = ValueNotifier<AuthState>(const AuthLoading());
  ref.listen<AuthState>(authNotifierProvider, (_, next) {
    authListenable.value = next;
  });
  ref.onDispose(authListenable.dispose);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authListenable,
    redirect: (context, state) {
      final auth = ref.read(authNotifierProvider);

      // Don't redirect while determining auth status
      if (auth is AuthLoading) return null;

      final authenticated = auth is AuthAuthenticated;
      final onAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation.startsWith('/confirm');

      if (!authenticated && !onAuthRoute) return '/login';
      if (authenticated && onAuthRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: '/confirm',
        builder: (_, state) =>
            ConfirmScreen(email: state.extra as String? ?? ''),
      ),
      GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => ShellScreen(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/', builder: (_, _) => const RecipesScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/community', builder: (_, _) => const FeedScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/batches', builder: (_, _) => const BatchesScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/inventory',
                builder: (_, _) => const InventoryScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/library', builder: (_, _) => const LibraryScreen()),
          ]),
        ],
      ),
    ],
  );
}
