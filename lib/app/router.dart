import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/diagnostics/presentation/health_check_screen.dart';

/// App router. Phase 0 exposes only the diagnostics route; auth guards and
/// payment/push deep links are added in later phases.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        name: 'diagnostics',
        builder: (context, state) => const HealthCheckScreen(),
      ),
    ],
  );
});
