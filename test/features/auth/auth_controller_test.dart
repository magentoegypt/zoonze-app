import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoonze_app/core/storage/secure_token_store.dart';
import 'package:zoonze_app/features/auth/data/auth_repository.dart';
import 'package:zoonze_app/features/auth/presentation/auth_controller.dart';

import '../../support/fakes.dart';

ProviderContainer _container({String? token, bool loginFails = false}) {
  final container = ProviderContainer(
    overrides: [
      secureTokenStoreProvider.overrideWithValue(FakeSecureTokenStore(token)),
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(loginFails: loginFails),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('AuthController', () {
    test('restores as guest when no token is stored', () async {
      final container = _container();
      container.read(authControllerProvider); // build -> _restore
      await pumpEventQueue();
      expect(container.read(authControllerProvider).status, AuthStatus.guest);
    });

    test('restores an authenticated session from a stored token', () async {
      final container = _container(token: 'persisted');
      container.read(authControllerProvider);
      await pumpEventQueue();
      final state = container.read(authControllerProvider);
      expect(state.isAuthenticated, isTrue);
      expect(state.customer?.email, 'layla@example.com');
    });

    test('login authenticates and exposes the customer', () async {
      final container = _container();
      await container
          .read(authControllerProvider.notifier)
          .login('layla@example.com', 'password1');
      final state = container.read(authControllerProvider);
      expect(state.isAuthenticated, isTrue);
      expect(state.customer?.fullName, 'Layla Hassan');
    });

    test('login propagates a failure on bad credentials', () async {
      final container = _container(loginFails: true);
      await expectLater(
        container.read(authControllerProvider.notifier).login('x@y.com', 'bad'),
        throwsA(isA<Object>()),
      );
    });

    test('resetPassword completes then signs the customer in', () async {
      final container = _container();
      await container
          .read(authControllerProvider.notifier)
          .resetPassword(
            email: 'layla@example.com',
            token: 'reset-code',
            newPassword: 'newpassword1',
          );
      expect(container.read(authControllerProvider).isAuthenticated, isTrue);
    });

    test('handleSessionExpired drops an authed session to guest', () async {
      final container = _container();
      final notifier = container.read(authControllerProvider.notifier);
      await notifier.login('layla@example.com', 'password1');
      expect(container.read(authControllerProvider).isAuthenticated, isTrue);

      await notifier.handleSessionExpired();
      expect(container.read(authControllerProvider).status, AuthStatus.guest);
    });

    test('logout returns to guest', () async {
      final container = _container();
      final notifier = container.read(authControllerProvider.notifier);
      await notifier.login('layla@example.com', 'password1');
      expect(container.read(authControllerProvider).isAuthenticated, isTrue);

      await notifier.logout();
      expect(container.read(authControllerProvider).status, AuthStatus.guest);
    });
  });
}
