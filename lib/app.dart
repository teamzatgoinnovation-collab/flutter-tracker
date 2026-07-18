import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/connection/connection_page.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/login/login_page.dart';
import 'features/projects/project_detail_page.dart';
import 'features/projects/projects_page.dart';
import 'features/shell/app_shell.dart';
import 'features/tasks/task_detail_page.dart';
import 'features/tasks/tasks_page.dart';
import 'features/tickets/tickets_page.dart';
import 'services/session.dart';
import 'theme.dart';

final _routerProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(trackerSessionProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: session,
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == '/login';
      if (!session.canEnterApp && !loggingIn) return '/login';
      if (session.canEnterApp && loggingIn) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/projects',
                builder: (context, state) => const ProjectsPage(),
                routes: [
                  GoRoute(
                    path: ':name',
                    builder: (context, state) {
                      final name = state.pathParameters['name']!;
                      return ProjectDetailPage(name: name);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tasks',
                builder: (context, state) => const TasksPage(),
                routes: [
                  GoRoute(
                    path: ':name',
                    builder: (context, state) {
                      final name = state.pathParameters['name']!;
                      return TaskDetailPage(name: name);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tickets',
                builder: (context, state) => const TicketsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/connection',
                builder: (context, state) => const ConnectionPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class TrackerApp extends ConsumerWidget {
  const TrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_routerProvider);
    return MaterialApp.router(
      title: 'Tracker',
      theme: buildTrackerTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
