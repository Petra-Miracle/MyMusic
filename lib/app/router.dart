import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/dock.dart';
import '../data/providers.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/home/home_screen.dart';
import '../features/library/library_screen.dart';
import '../features/library/playlist_detail_screen.dart';
import '../features/player/lyrics_screen.dart';
import '../features/player/now_playing_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/search/search_screen.dart';

final _rootKey = GlobalKey<NavigatorState>();

const _publicRoutes = {'/login', '/register'};

final routerProvider = Provider<GoRouter>((ref) {
  // Router dibuat sekali; perubahan auth hanya memicu redirect ulang.
  final authChanges = ValueNotifier(0);
  ref.listen(authProvider, (_, _) => authChanges.value++);
  ref.onDispose(authChanges.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    refreshListenable: authChanges,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final loc = state.matchedLocation;
      if (auth.isLoading && !auth.hasValue) return loc == '/splash' ? null : '/splash';
      final loggedIn = auth.value != null;
      if (!loggedIn) return _publicRoutes.contains(loc) ? null : '/login';
      if (loc == '/splash' || _publicRoutes.contains(loc)) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
      GoRoute(
        path: '/player',
        parentNavigatorKey: _rootKey,
        pageBuilder: (_, state) => _slideUp(state, const NowPlayingScreen()),
        routes: [
          GoRoute(
            path: 'lyrics',
            parentNavigatorKey: _rootKey,
            pageBuilder: (_, state) => _slideUp(state, const LyricsScreen()),
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _TabShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, _) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/search', builder: (_, _) => const SearchScreen())]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/library',
              builder: (_, _) => const LibraryScreen(),
              routes: [
                GoRoute(
                  path: 'playlist/:id',
                  builder: (_, state) => PlaylistDetailScreen(id: state.pathParameters['id']!),
                ),
              ],
            ),
          ]),
        ],
      ),
    ],
  );
});

CustomTransitionPage<void> _slideUp(GoRouterState state, Widget child) => CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      transitionsBuilder: (_, animation, _, child) => SlideTransition(
        position: Tween(begin: const Offset(0, 1), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );

class _TabShell extends StatelessWidget {
  const _TabShell({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: Dock(
        currentTab: shell.currentIndex,
        // Tap tab yang sedang aktif = kembali ke halaman awal tab itu.
        onTabSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
      ),
    );
  }
}
