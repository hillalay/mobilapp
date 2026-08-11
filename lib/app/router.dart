import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/dashboard/dashboard_page.dart';
import '../features/exams/exams_page.dart';
import '../features/exams/exam_create_entry_page.dart';
import '../features/exams/exam_general_type_page.dart';
import '../features/exams/exam_general_form_page.dart';
import '../features/exams/exam_branch_lesson_page.dart';
import '../features/exams/exam_branch_form_page.dart';
import '../features/exams/exam_models.dart';
import '../features/exams/exam_analytics_page.dart';
import '../features/exams/exams_analysis_page.dart';
import '../features/exams/exam_general_edit_page.dart';
import '../features/exams/exam_branch_edit_page.dart';

import '../core/auth_providers.dart';
import '../features/auth/login_page.dart';
import '../features/leaderboard/leaderboard_page.dart';

import '../features/profile/onboarding_page.dart';
import '../features/profile/profile_controller.dart';
import '../features/profile/profile_page.dart';

import '../features/timer/timer_page.dart';

import '../features/topics/topics_page.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  // Router yalnızca BİR kez kurulur. Eskiden profileProvider `watch` ediliyordu;
  // profil her yenilendiğinde (açılışta senkron çekmesi de yeniliyor) yeni bir
  // GoRouter üretiliyor, yeni router da initialLocation'a dönüyordu. Bu yüzden
  // onboarding her açılışta karşımıza çıkıyordu. Artık `refreshListenable` ile
  // sadece redirect tekrar çalışıyor; kullanıcı bulunduğu sekmede kalıyor.
  final refresh = ValueNotifier<int>(0);
  ref.listen(profileProvider, (_, _) => refresh.value++);
  ref.listen(requiresLoginProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final profileAsync = ref.read(profileProvider);
      final requiresLogin = ref.read(requiresLoginProvider);

      final location = state.matchedLocation;
      final goingToLogin = location == '/login';
      final goingToOnboarding = location == '/onboarding';

      if (requiresLogin) return goingToLogin ? null : '/login';

      if (profileAsync.isLoading) return null;

      final hasProfile = profileAsync.value != null;

      if (goingToLogin) return hasProfile ? '/dashboard' : '/onboarding';
      if (!hasProfile && !goingToOnboarding) return '/onboarding';
      if (hasProfile && goingToOnboarding) return '/dashboard';

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        // '/' ekranı yok, her zaman bir yere yönlenmeli. Profil hâlâ
        // yükleniyorsa dashboard'a git; profil gelmezse üstteki redirect
        // onboarding'e çevirir. Tersini yapmak (yüklenirken onboarding)
        // mevcut kullanıcıya her açılışta onboarding göstermek olurdu.
        redirect: (context, state) {
          final profileAsync = ref.read(profileProvider);
          if (profileAsync.isLoading) return '/dashboard';
          return profileAsync.value != null ? '/dashboard' : '/onboarding';
        },
      ),

      // Giriş (bottom bar YOK)
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),

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
            path: '/stopwatch',
            builder: (context, state) => const TimerPage(),
          ),
          // '/timer' altında: alt menüde Kronometre sekmesi seçili kalsın.
          GoRoute(
            path: '/timer/leaderboard',
            builder: (context, state) => const LeaderboardPage(),
          ),

          GoRoute(
            path: '/exams',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ExamsPage()),
          ),
          GoRoute(
            path: '/exams/new',
            builder: (context, state) => const ExamCreateEntryPage(),
          ),

          // TEK analytics route 
          GoRoute(
            path: '/exams/analytics',
            builder: (context, state) {
              final type = state.extra;
              if (type is! ExamType) return const ExamsPage(); // fallback
              return ExamAnalyticsPage(type: type);
            },
          ),
                    // GENERAL EDIT 
          GoRoute(
            path: '/exams/general/edit',
            builder: (context, state) {
              final exam = state.extra;
              if (exam is! ExamEntry) return const ExamsPage(); // fallback
              return ExamGeneralEditPage(exam: exam);
            },
          ),
          
          GoRoute(
            path: '/exams/general/type',
            builder: (context, state) => const ExamGeneralTypePage(),
          ),
          GoRoute(
            path: '/exams/general/form',
            builder: (context, state) {
              final type = state.extra;
              if (type is! ExamType) return const ExamGeneralTypePage();
              return ExamGeneralFormPage(type: type);
            },
          ),

          GoRoute(
            path: '/exams/branch/lesson',
            builder: (context, state) => const ExamBranchLessonPage(),
          ),
          GoRoute(
            path: '/exams/branch/form',
            builder: (context, state) {
              final lesson = state.extra;
              if (lesson is! String) return const ExamsPage(); // fallback
              return ExamBranchFormPage(lesson: lesson);
            },
          ),

          GoRoute(
            path: '/exams/analysis',
            builder: (context, state) => const ExamsAnalysisPage(),
          ),

          // BRANCH EDIT
          GoRoute(
            path: '/exams/branch/edit',
            builder: (context, state) {
              final exam = state.extra;
              if (exam is! ExamEntry) return const ExamsPage(); // fallback
              return ExamBranchEditPage(exam: exam);
            },
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
