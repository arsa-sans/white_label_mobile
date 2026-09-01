import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../features/auth/presentation/views/login_view.dart';
import '../../features/auth/presentation/views/tenant_select_view.dart';
import '../../features/gate/presentation/views/gate_scanner_view.dart';
import '../../features/organizer/presentation/views/organizer_summary_view.dart';

/// RouterNotifier listens to AuthState changes and triggers GoRouter redirection
/// WITHOUT destroying and recreating the GoRouter instance.
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authProvider,
      (previous, next) {
        // Only notify router if auth status or role actually changed
        if (previous?.isAuthenticated != next.isAuthenticated ||
            previous?.user?.role != next.user?.role) {
          notifyListeners();
        }
      },
    );
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authProvider);
    final isAuth = authState.isAuthenticated;
    final isLoggingIn = state.matchedLocation == '/login' ||
        state.matchedLocation == '/tenant-select';

    if (!isAuth && !isLoggingIn) return '/login';

    if (isAuth && isLoggingIn) {
      final role = authState.user?.role ?? 'visitor';
      if (role == 'gate_staff') return '/gate-scanner';
      if (role == 'organizer' || role == 'admin') return '/organizer-summary';
      // Vendor & Visitor are guided to web portal
      return null;
    }

    return null;
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: notifier.redirect,
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
        path: '/organizer-summary',
        builder: (context, state) => const OrganizerSummaryView(),
      ),
    ],
  );
});
