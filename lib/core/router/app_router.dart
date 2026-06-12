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
import '../../features/community/user_profile_screen.dart';
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
import '../../features/mixes/mix_models.dart';
import '../../features/mixes/mix_session_screen.dart';
import '../../features/settings/settings_screen.dart';

part 'app_router.g.dart';

// Shared page transition: gentle upward fade-in (feels native on both platforms)
CustomTransitionPage<T> _slide<T>(GoRouterState state, Widget child) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, _, child) {
      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      final slide = Tween(
        begin: const Offset(0.0, 0.04),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
      return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}

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
      final loc = state.matchedLocation;

      final onAuthRoute = loc == '/login' ||
          loc == '/login/email' ||
          loc == '/register' ||
          loc.startsWith('/confirm');

      if (auth is AuthAuthenticated) {
        // Redirect away from auth screens once signed in
        if (onAuthRoute) return startupTab;
        return null;
      }

      // AuthLoading and AuthUnauthenticated both land on /login.
      // The router re-evaluates when auth state changes, so authenticated
      // users are forwarded to the app as soon as the session check resolves.
      if (onAuthRoute) return null;
      return '/login';
    },
    routes: [
      // ── Auth ──────────────────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        pageBuilder: (_, state) => _slide(state, const LoginScreen()),
        routes: [
          GoRoute(
            path: 'email',
            pageBuilder: (_, state) => _slide(state, const EmailLoginScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (_, state) => _slide(state, const RegisterScreen()),
      ),
      GoRoute(
        path: '/confirm',
        pageBuilder: (_, state) {
          final args = state.extra as ConfirmArgs?;
          return _slide(state,
              ConfirmScreen(email: args?.email ?? '', password: args?.password));
        },
      ),

      // ── Profile & Settings ────────────────────────────────────────────────
      GoRoute(
        path: '/profile',
        pageBuilder: (_, state) => _slide(state, const ProfileScreen()),
      ),
      GoRoute(
        path: '/user/:uid',
        pageBuilder: (_, state) => _slide(
          state,
          UserProfileScreen(uid: state.pathParameters['uid']!),
        ),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (_, state) => _slide(state, const SettingsScreen()),
      ),

      // ── Recipes (outside shell so there's no bottom nav) ──────────────────
      GoRoute(
        path: '/recipe/new',
        pageBuilder: (_, state) => _slide(state, const RecipeEditorScreen()),
      ),
      GoRoute(
        path: '/recipe/:id',
        pageBuilder: (_, state) => _slide(
          state,
          RecipeDetailScreen(recipeId: state.pathParameters['id']!),
        ),
        routes: [
          GoRoute(
            path: 'edit',
            pageBuilder: (_, state) => _slide(
              state,
              RecipeEditorScreen(existing: state.extra as RecipeDetail?),
            ),
          ),
        ],
      ),

      // ── Mix session (outside shell) ───────────────────────────────────────
      GoRoute(
        path: '/mix/:id',
        pageBuilder: (_, state) => _slide(
          state,
          MixSessionScreen(
            mixId: state.pathParameters['id']!,
            initialMix: state.extra as GlazeMix?,
          ),
        ),
      ),

      // ── Schedules (outside shell) ─────────────────────────────────────────
      GoRoute(
        path: '/schedule/new',
        pageBuilder: (_, state) => _slide(state, const ScheduleEditorScreen()),
      ),
      GoRoute(
        path: '/schedule/:id',
        pageBuilder: (_, state) => _slide(
          state,
          ScheduleDetailScreen(scheduleId: state.pathParameters['id']!),
        ),
        routes: [
          GoRoute(
            path: 'edit',
            pageBuilder: (_, state) => _slide(
              state,
              ScheduleEditorScreen(existing: state.extra as ScheduleDetail?),
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
