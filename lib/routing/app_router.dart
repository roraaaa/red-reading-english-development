import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/repositories/auth_repository.dart';
import '../domain/models/passage.dart';
import '../ui/features/account/views/account_screen.dart';
import '../ui/features/assess/views/assess_intro_screen.dart';
import '../ui/features/auth/views/login_screen.dart';
import '../ui/features/auth/views/sign_up_screen.dart';
import '../ui/features/home/views/home_screen.dart';
import '../ui/features/materials/views/levels_screen.dart';
import '../ui/features/materials/views/stories_screen.dart';
import '../ui/features/progress/views/progress_screen.dart';
import '../ui/features/session/views/reading_session_screen.dart';
import '../ui/features/splash/views/splash_screen.dart';

abstract final class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const signUp = '/signup';
  static const home = '/';
  static const assess = '/assess';
  static const materials = '/materials';
  static const progress = '/progress';
  static const account = '/account';

  static String assessSession(Difficulty d) => '/assess/session?difficulty=${d.name}';
  static String level(String levelId) => '/materials/$levelId';
  static String story(String levelId, String passageId) => '/materials/$levelId/$passageId';
}

GoRouter createRouter(AuthRepository auth) {
  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: auth,
    redirect: (context, state) {
      final location = state.matchedLocation;
      if (location == Routes.splash) return null;
      if (!auth.isInitialized) return Routes.splash;

      final onAuthScreen = location == Routes.login || location == Routes.signUp;
      if (!auth.isSignedIn) return onAuthScreen ? null : Routes.login;
      if (onAuthScreen) return Routes.home;
      return null;
    },
    routes: [
      GoRoute(path: Routes.splash, pageBuilder: (c, s) => _fade(s, const SplashScreen())),
      GoRoute(path: Routes.login, pageBuilder: (c, s) => _fade(s, const LoginScreen())),
      GoRoute(path: Routes.signUp, pageBuilder: (c, s) => _slide(s, const SignUpScreen())),
      GoRoute(
        path: Routes.home,
        pageBuilder: (c, s) => _fade(s, const HomeScreen()),
        routes: [
          GoRoute(
            path: 'assess',
            pageBuilder: (c, s) => _slide(s, const AssessIntroScreen()),
            routes: [
              GoRoute(
                path: 'session',
                pageBuilder: (c, s) => _slide(
                  s,
                  ReadingSessionScreen.assessment(
                    difficulty:
                        Difficulty.fromName(s.uri.queryParameters['difficulty']) ?? Difficulty.easy,
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'materials',
            pageBuilder: (c, s) => _slide(s, const LevelsScreen()),
            routes: [
              GoRoute(
                path: ':levelId',
                pageBuilder: (c, s) => _slide(s, StoriesScreen(levelId: s.pathParameters['levelId']!)),
                routes: [
                  GoRoute(
                    path: ':passageId',
                    pageBuilder: (c, s) => _slide(
                      s,
                      ReadingSessionScreen.material(passageId: s.pathParameters['passageId']!),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(path: 'progress', pageBuilder: (c, s) => _slide(s, const ProgressScreen())),
          GoRoute(path: 'account', pageBuilder: (c, s) => _slide(s, const AccountScreen())),
        ],
      ),
    ],
    errorBuilder: (context, state) => const _NotFoundScreen(),
  );
}

CustomTransitionPage<void> _fade(GoRouterState state, Widget child) => CustomTransitionPage(
  key: state.pageKey,
  child: child,
  transitionDuration: const Duration(milliseconds: 450),
  transitionsBuilder: (context, animation, secondary, child) =>
      FadeTransition(opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut), child: child),
);

CustomTransitionPage<void> _slide(GoRouterState state, Widget child) => CustomTransitionPage(
  key: state.pageKey,
  child: child,
  transitionDuration: const Duration(milliseconds: 380),
  reverseTransitionDuration: const Duration(milliseconds: 300),
  transitionsBuilder: (context, animation, secondary, child) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(begin: const Offset(0.08, 0), end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  },
);

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Oops! That page wandered off.'),
          const SizedBox(height: 16),
          FilledButton(onPressed: () => context.go(Routes.home), child: const Text('Go home')),
        ],
      ),
    ),
  );
}
