import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../features/auth/presentation/views/login_view.dart';
import '../../features/auth/presentation/views/register_view.dart';
import '../../features/auth/presentation/views/tenant_select_view.dart';
import '../../features/visitor/screens/catalog_screen.dart';
import '../../features/visitor/screens/event_detail_screen.dart';
import '../../features/visitor/screens/checkout_screen.dart';
import '../../features/visitor/screens/my_tickets_screen.dart';
import '../../features/visitor/screens/wallet_screen.dart';
import '../../features/gate/screens/gate_scanner_screen.dart';
import '../../features/booth/screens/booth_cashier_screen.dart';
import '../../features/organizer/screens/organizer_summary_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (BuildContext context, GoRouterState state) {
      final isAuth = authState.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/tenant-select';

      if (!isAuth && !isLoggingIn) return '/login';

      if (isAuth && isLoggingIn) {
        // Redirect to role home screen
        final role = authState.user?.role ?? 'visitor';
        if (role == 'gate_staff') return '/gate-scanner';
        if (role == 'vendor') return '/booth-cashier';
        if (role == 'organizer') return '/organizer-summary';
        return '/catalog'; // visitor / admin default
      }

      return null;
    },
    routes: [
      // ── Auth Views (MVVM) ──────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterView(),
      ),
      GoRoute(
        path: '/tenant-select',
        builder: (context, state) => const TenantSelectView(),
      ),

      // ── Visitor Screens ────────────────────────────────────────────────────
      GoRoute(
        path: '/catalog',
        builder: (context, state) => const CatalogScreen(),
      ),
      GoRoute(
        path: '/event-detail/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return EventDetailScreen(eventId: id);
        },
      ),
      GoRoute(
        path: '/checkout/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final seatId = state.uri.queryParameters['seatId'] ?? '';
          return CheckoutScreen(eventId: id, seatId: seatId);
        },
      ),
      GoRoute(
        path: '/my-tickets',
        builder: (context, state) => const MyTicketsScreen(),
      ),
      GoRoute(
        path: '/wallet',
        builder: (context, state) => const WalletScreen(),
      ),

      // ── Staff / Role Screens ───────────────────────────────────────────────
      GoRoute(
        path: '/gate-scanner',
        builder: (context, state) => const GateScannerScreen(),
      ),
      GoRoute(
        path: '/booth-cashier',
        builder: (context, state) => const BoothCashierScreen(),
      ),
      GoRoute(
        path: '/organizer-summary',
        builder: (context, state) => const OrganizerSummaryScreen(),
      ),
    ],
  );
});
