import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../features/auth/presentation/views/login_view.dart';
import '../../features/auth/presentation/views/register_view.dart';
import '../../features/auth/presentation/views/tenant_select_view.dart';
import '../../features/gate/presentation/views/gate_scanner_view.dart';
import '../../features/booth/presentation/views/booth_cashier_view.dart';
import '../../features/visitor/presentation/views/catalog_view.dart';
import '../../features/visitor/presentation/views/event_detail_view.dart';
import '../../features/visitor/presentation/views/checkout_view.dart';
import '../../features/visitor/presentation/views/my_tickets_view.dart';
import '../../features/visitor/presentation/views/wallet_view.dart';
import '../../features/organizer/presentation/views/organizer_summary_view.dart';

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

      // ── Visitor Views (MVVM) ───────────────────────────────────────────────
      GoRoute(
        path: '/catalog',
        builder: (context, state) => const CatalogView(),
      ),
      GoRoute(
        path: '/event-detail/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return EventDetailView(eventId: id);
        },
      ),
      GoRoute(
        path: '/checkout/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final seatId = state.uri.queryParameters['seatId'] ?? '';
          return CheckoutView(eventId: id, seatId: seatId);
        },
      ),
      GoRoute(
        path: '/my-tickets',
        builder: (context, state) => const MyTicketsView(),
      ),
      GoRoute(
        path: '/wallet',
        builder: (context, state) => const WalletView(),
      ),

      // ── Staff & Organizer Views (MVVM) ────────────────────────────────────
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
