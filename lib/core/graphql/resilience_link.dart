import 'dart:async';

import 'package:gql/ast.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../error/graphql_failure_mapper.dart';

/// A terminating-adjacent link that adds two cross-cutting concerns to every
/// operation (CLAUDE.md §3.2 + §7):
///
/// 1. **Retry-with-backoff** on transient transport errors (timeouts, dropped
///    connections, 5xx / gateway / "temporarily unavailable"). Only **queries**
///    are retried — never mutations — so a lost response on `placeOrder` /
///    `addProductsToCart` can't double-submit.
/// 2. **Mid-session auth detection**: if a response carries a
///    `graphql-authorization`/`graphql-authentication` error, [onAuthError] is
///    invoked so the session can be dropped to guest immediately (Magento
///    returns these as HTTP 200 + an errors payload, so they never throw).
class ResilienceLink extends Link {
  ResilienceLink({
    required this.onAuthError,
    this.maxAttempts = 3,
    this.initialBackoff = const Duration(milliseconds: 400),
  });

  /// Called (at most once per operation) when the response reports the token is
  /// no longer valid. Should be cheap/non-throwing — typically schedules a
  /// logout on a microtask.
  final void Function() onAuthError;

  /// Total attempts for a retryable (query) operation, including the first.
  final int maxAttempts;

  /// Base delay; doubles each retry (400ms → 800ms → 1600ms …).
  final Duration initialBackoff;

  @override
  Stream<Response> request(Request request, [NextLink? forward]) async* {
    assert(forward != null, 'ResilienceLink must not be the terminating link');
    final retryable = _isQuery(request);
    var attempt = 0;
    while (true) {
      attempt++;
      try {
        await for (final response in forward!(request)) {
          if (_responseHasAuthError(response)) onAuthError();
          yield response;
        }
        return;
      } catch (error) {
        if (!retryable || attempt >= maxAttempts || !_isTransient(error)) {
          rethrow;
        }
        await Future<void>.delayed(initialBackoff * (1 << (attempt - 1)));
      }
    }
  }

  static bool _isQuery(Request request) {
    for (final def in request.operation.document.definitions) {
      if (def is OperationDefinitionNode) {
        return def.type == OperationType.query;
      }
    }
    return false;
  }

  static bool _responseHasAuthError(Response response) {
    final errors = response.errors;
    if (errors == null || errors.isEmpty) return false;
    return errors.any(isAuthGraphqlError);
  }

  /// String-based, version-robust transient detection (mirrors the failure
  /// mapper's defensive style). Auth/4xx/validation errors are NOT transient.
  static bool _isTransient(Object error) {
    if (error is TimeoutException) return true;
    final s = error.toString().toLowerCase();
    return s.contains('socket') ||
        s.contains('timeout') ||
        s.contains('timed out') ||
        s.contains('connection') ||
        s.contains('failed host lookup') ||
        s.contains('temporarily') ||
        s.contains('unavailable') ||
        s.contains('gateway') ||
        s.contains('500') ||
        s.contains('502') ||
        s.contains('503') ||
        s.contains('504');
  }
}
