import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../features/auth/presentation/views/login_view.dart';
import '../../features/auth/presentation/views/tenant_select_view.dart';
import '../../features/gate/presentation/views/gate_scanner_view.dart';
import '../../features/booth/presentation/views/booth_cashier_view.dart';
import '../../features/organizer/presentation/views/organizer_summary_view.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (BuildContext context, GoRouterState state) {
      final isAuth = authState.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/tenant-select';

      if (!isAuth && !isLoggingIn) return '/login';

      if (isAuth && isLoggingIn) {
        final role = authState.user?.role ?? 'visitor';
        if (role == 'gate_staff') return '/gate-scanner';
        if (role == 'vendor') return '/booth-cashier';
        if (role == 'organizer' || role == 'admin') return '/organizer-summary';
        // Visitor is not allowed on mobile app
        return null;
      }

      return null;
    },
    routes: [
      // Auth Views (MVVM)
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: '/tenant-select',
        builder: (context, state) => const TenantSelectView(),
      ),

      // Staff & Organizer Views (MVVM)
      GoRoute(
        path: '/gate-scanner',
        builder: (context, state) => const GateScannerView(),
      ),
      GoRoute(
        path: '/booth-cashier',
        builder: (context, state) => const BoothCashierView(),
      ),
      GoRoute(
        path: '/organizer-summary',
        builder: (context, state) => const OrganizerSummaryView(),
      ),
    ],
  );
});

