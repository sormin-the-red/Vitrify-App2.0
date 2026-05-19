import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../auth/auth_notifier.dart';
import '../auth/auth_state.dart';
import '../settings/settings_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/email_login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/confirm_screen.dart' show ConfirmScreen, ConfirmArgs;
import '../../features/shell/shell_screen.dart';
import '../../features/community/feed_screen.dart';
import '../../features/recipes/recipes_screen.dart';
import '../../features/recipes/recipe_detail_screen.dart';
import '../../features/recipes/recipe_editor_screen.dart';
import '../../features/recipes/recipe_models.dart';
import '../../features/schedules/schedule_detail_screen.dart';
import '../../features/schedules/schedule_editor_screen.dart';
import '../../features/schedules/schedule_models.dart';
import '../../features/batches/batches_screen.dart';
import '../../features/batches/batch_detail_screen.dart';
import '../../features/inventory/inventory_screen.dart';
import '../../features/library/library_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/settings/settings_screen.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(AppRouterRef ref) {
  final authListenable = ValueNotifier<AuthState>(const AuthLoading());
  ref.listen<AuthState>(authNotifierProvider, (_, next) {
    authListenable.value = next;
  });
  ref.onDispose(authListenable.dispose);

  final startupTab = ref.read(settingsNotifierProvider).startupTab;

  return GoRouter(
    initialLocation: startupTab,
    refreshListenable: authListenable,
    redirect: (context, state) {
      final auth = ref.read(authNotifierProvider);
      if (auth is AuthLoading) return null;

      final authenticated = auth is AuthAuthenticated;
      final loc = state.matchedLocation;
      final onAuthRoute = loc == '/login' ||
          loc == '/login/email' ||
          loc == '/register' ||
          loc.startsWith('/confirm');

      if (authenticated && onAuthRoute) {
        final from = state.uri.queryParameters['from'];
        return (from != null && from.isNotEmpty) ? from : startupTab;
      }

      if (!authenticated && (loc == '/settings' || loc == '/profile')) {
        return '/login?from=${Uri.encodeComponent(loc)}';
      }

      return null;
    },
    routes: [
      // ── Auth ──────────────────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (_, _) => const LoginScreen(),
        routes: [
          GoRoute(
            path: 'email',
            builder: (_, _) => const EmailLoginScreen(),
          ),
        ],
      ),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: '/confirm',
        builder: (_, state) {
          final args = state.extra as ConfirmArgs?;
          return ConfirmScreen(email: args?.email ?? '', password: args?.password);
        },
      ),

      // ── Profile & Settings ────────────────────────────────────────────────
      GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),

      // ── Recipes (outside shell so there's no bottom nav) ──────────────────
      GoRoute(
        path: '/recipe/new',
        builder: (_, _) => const RecipeEditorScreen(),
      ),
      GoRoute(
        path: '/recipe/:id',
        builder: (_, state) =>
            RecipeDetailScreen(recipeId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (_, state) => RecipeEditorScreen(
              existing: state.extra as RecipeDetail?,
            ),
          ),
        ],
      ),

      // ── Schedules (outside shell) ─────────────────────────────────────────
      GoRoute(
        path: '/schedule/new',
        builder: (_, _) => const ScheduleEditorScreen(),
      ),
      GoRoute(
        path: '/schedule/:id',
        builder: (_, state) =>
            ScheduleDetailScreen(scheduleId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (_, state) => ScheduleEditorScreen(
              existing: state.extra as ScheduleDetail?,
            ),
          ),
        ],
      ),

      // ── Main shell (bottom nav) ───────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) =>
            ShellScreen(navigationShell: shell),
        branches: [
          // 0 — Feed
          StatefulShellBranch(routes: [
            GoRoute(path: '/feed', builder: (_, _) => const FeedScreen()),
          ]),
          // 1 — Studio
          StatefulShellBranch(routes: [
            GoRoute(path: '/studio', builder: (_, _) => const RecipesScreen()),
          ]),
          // 2 — Batches
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/batches',
              builder: (_, _) => const BatchesScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (_, state) => BatchDetailScreen(
                    batchId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ]),
          // 3 — Inventory
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/inventory',
                builder: (_, _) => const InventoryScreen()),
          ]),
          // 4 — Library
          StatefulShellBranch(routes: [
            GoRoute(
                path: '/library',
                builder: (_, _) => const LibraryScreen()),
          ]),
        ],
      ),
    ],
  );
}
