import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'screens/auth/login_screen.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/auth/account_dashboard_screen.dart';
import 'screens/setup/event_name_screen.dart';
import 'screens/setup/timetable_setup_screen.dart';
import 'screens/setup/group_setup_screen.dart';
import 'screens/main_layout.dart';
import 'screens/group/group_detail_screen.dart';
import 'screens/tabs/global_timeline_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/members/member_management_screen.dart';
import 'screens/admin/audit_log_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/main',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/role_selection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/account',
        builder: (context, state) => const AccountDashboardScreen(),
      ),
      GoRoute(
        path: '/setup/event_name',
        builder: (context, state) => const EventNameScreen(),
      ),
      GoRoute(
        path: '/setup/timetable',
        builder: (context, state) => const TimetableSetupScreen(),
      ),
      GoRoute(
        path: '/setup/group',
        builder: (context, state) => const GroupSetupScreen(),
      ),
      GoRoute(
        path: '/main',
        builder: (context, state) => const MainLayout(),
      ),
      GoRoute(
        path: '/group/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return GroupDetailScreen(groupId: id);
        },
      ),
      GoRoute(
        path: '/global_timeline',
        builder: (context, state) => const GlobalTimelineScreen(),
      ),
      GoRoute(
        path: '/admin_dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/members',
        builder: (context, state) => const MemberManagementScreen(),
      ),
      GoRoute(
        path: '/audit_log',
        builder: (context, state) => const AuditLogScreen(),
      ),
    ],
  );
});
