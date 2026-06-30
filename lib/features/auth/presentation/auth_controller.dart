import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/graphql/graphql_client.dart';
import '../../../core/storage/secure_token_store.dart';
import '../../notifications/data/device_token_repository.dart';
import '../data/auth_repository.dart';
import '../domain/customer.dart';

enum AuthStatus { unknown, authenticated, guest }

class AuthState {
  const AuthState({this.customer, this.status = AuthStatus.unknown});

  final Customer? customer;
  final AuthStatus status;

  bool get isAuthenticated => status == AuthStatus.authenticated;
}

/// Owns the customer session: restores a persisted token on startup, and drives
/// login / register / logout / password-reset. The token lives in secure
/// storage; [AuthLink] reads it per request.
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future.microtask(_restore);
    return const AuthState();
  }

  SecureTokenStore get _tokens => ref.read(secureTokenStoreProvider);
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<void> _restore() async {
    final token = await _tokens.read();
    if (token == null) {
      state = const AuthState(status: AuthStatus.guest);
      return;
    }
    try {
      final customer = await _repo.fetchCustomer();
      state = AuthState(customer: customer, status: AuthStatus.authenticated);
    } on Object {
      // Token invalid/expired -> drop it and continue as guest.
      await _tokens.clear();
      state = const AuthState(status: AuthStatus.guest);
    }
  }

  Future<void> login(String email, String password) async {
    final token = await _repo.login(email, password);
    await _tokens.write(token);
    // Reset the cache so guest data is dropped; AuthLink now sends the bearer.
    ref.invalidate(graphqlClientProvider);
    final customer = await _repo.fetchCustomer();
    state = AuthState(customer: customer, status: AuthStatus.authenticated);
    // Re-bind this device's FCM token to the now-authenticated customer.
    unawaited(ref.read(deviceTokenSyncProvider).register());
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    await _repo.register(
      firstName: firstName,
      lastName: lastName,
      email: email,
      password: password,
    );
    await login(email, password);
  }

  Future<void> logout() async {
    // Unbind this device first, while the bearer is still valid (the resolver
    // scopes the delete to the authenticated customer).
    await ref.read(deviceTokenSyncProvider).unregister();
    await _repo.revokeToken();
    await _tokens.clear();
    ref.invalidate(graphqlClientProvider);
    state = const AuthState(status: AuthStatus.guest);
  }

  Future<void> requestPasswordReset(String email) =>
      _repo.requestPasswordReset(email);

  /// Completes a reset with the emailed token, then signs the customer in with
  /// their new password so they land authenticated.
  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    await _repo.resetPassword(
      email: email,
      token: token,
      newPassword: newPassword,
    );
    await login(email, newPassword);
  }

  /// Invoked when a live request reports the token is invalid/expired
  /// mid-session (the resilience link detects `graphql-authorization`). Drops
  /// the session to guest locally — no revoke round-trip, since the token is
  /// already rejected — and resets the cache so customer data is cleared.
  Future<void> handleSessionExpired() async {
    // Clear the token unconditionally. A stale/expired token can linger in
    // secure storage even while the state already reads guest — AuthLink sends
    // whatever token is stored on every request, so Magento then rejects every
    // call with "Consumer key has expired". Wiping it lets requests proceed as
    // guest and recover, instead of failing forever.
    await _tokens.clear();
    ref.invalidate(graphqlClientProvider);
    if (state.status != AuthStatus.guest) {
      state = const AuthState(status: AuthStatus.guest);
    }
  }

  /// Re-fetches the customer profile (e.g. after an Edit Profile save).
  Future<void> refreshCustomer() async {
    if (!state.isAuthenticated) return;
    try {
      final customer = await _repo.fetchCustomer();
      state = AuthState(customer: customer, status: AuthStatus.authenticated);
    } on Object {
      // keep current profile on failure
    }
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
