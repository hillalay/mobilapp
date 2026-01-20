import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/dashboard/dashboard_page.dart';
import '../features/exams/exams_page.dart';
import '../features/profile/onboarding_page.dart';
import '../features/profile/profile_controller.dart';
import '../features/profile/profile_page.dart';
import '../features/timer/timer_page.dart';
import '../features/topics/topics_page.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  // Profil state’ini dinle: değişince router redirect’i yeniden çalışsın
  final profileAsync = ref.watch(profileProvider);
  final hasProfile = profileAsync.value != null;
  final isLoading = profileAsync.isLoading;


  return GoRouter(
    // App ilk açılış: eğer profil yoksa onboarding’e gidecek zaten
    initialLocation: '/dashboard',

    redirect: (context, state) {
      final goingToOnboarding = state.matchedLocation == '/onboarding';
      final profileAsync = ref.read(profileProvider);
      if(profileAsync.isLoading){
        return null; //bekle
      }
      final hasProfile = profileAsync.value != null;

      if(!hasProfile && !goingToOnboarding) {
        return '/onboarding';
      }
      if(hasProfile && goingToOnboarding) {
        return '/dashboard';
      }
      return null; //değişiklik yok
    },
    routes: [
      // Onboarding (bottom bar YOK)
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),

      // App shell (bottom bar VAR)
      ShellRoute(
        builder: (context, state, child) => _AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DashboardPage()),
          ),
          GoRoute(
            path: '/timer',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TimerPage()),
          ),
          GoRoute(
            path: '/exams',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ExamsPage()),
          ),
          GoRoute(
            path: '/topics',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TopicsPage()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfilePage()),
          ),
        ],
      ),
    ],
  );
});

class _AppShell extends StatelessWidget {
  const _AppShell({required this.child});

  final Widget child;

  static const tabs = [
    ('/dashboard', 'Ana Sayfa', Icons.home_outlined),
    ('/timer', 'Kronometre', Icons.timer_outlined),
    ('/exams', 'Denemeler', Icons.analytics_outlined),
    ('/topics', 'Takip', Icons.list_alt_outlined),
    ('/profile', 'Profil', Icons.person_outline),
  ];

  int _locationToIndex(String location) {
    final index = tabs.indexWhere((t) => location.startsWith(t.$1));
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _locationToIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => context.go(tabs[i].$1),
        destinations: [
          for (final t in tabs)
            NavigationDestination(icon: Icon(t.$3), label: t.$2),
        ],
      ),
    );
  }
}
