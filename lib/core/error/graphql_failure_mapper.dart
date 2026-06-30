import 'package:graphql_flutter/graphql_flutter.dart';

import 'failure.dart';

/// Maps a graphql_flutter [OperationException] to a domain [Failure].
///
/// Kept defensive (string-based link inspection) so it stays robust across
/// graphql_flutter point releases that rename concrete exception classes.
Failure mapOperationException(OperationException exception) {
  final linkException = exception.linkException;
  if (linkException != null) {
    final raw = linkException.toString();
    final detail = raw.length > 400 ? '${raw.substring(0, 400)}…' : raw;
    final text = raw.toLowerCase();
    // A non-JSON / HTML body (WAF, CloudFront error page, maintenance) — or a
    // response the transport couldn't decode into JSON — surfaces as a
    // parse/format failure rather than a clean GraphQL error. Keep the raw
    // cause in `detail` so transport-specific issues (e.g. an undecoded
    // compressed body on iOS) stay diagnosable on the connection-test screen.
    if (text.contains('format') ||
        text.contains('parse') ||
        text.contains('html') ||
        text.contains('<!doctype')) {
      return Failure(FailureKind.service, detail: detail);
    }
    return Failure(FailureKind.network, detail: detail);
  }

  final graphqlErrors = exception.graphqlErrors;
  if (graphqlErrors.isNotEmpty) {
    final isAuth = graphqlErrors.any(isAuthGraphqlError);
    if (isAuth) return const Failure(FailureKind.auth);
    return Failure(FailureKind.server, detail: graphqlErrors.first.message);
  }

  return const Failure(FailureKind.unknown);
}

/// True when a GraphQL error indicates the customer token is invalid/expired
/// (Magento returns these as a 200 + errors payload, category
/// `graphql-authorization`/`graphql-authentication`). Shared by the failure
/// mapper and the resilience link's mid-session logout trigger.
bool isAuthGraphqlError(GraphQLError error) {
  final category = error.extensions?['category'];
  if (category == 'graphql-authorization' ||
      category == 'graphql-authentication') {
    return true;
  }
  final message = error.message.toLowerCase();
  return message.contains('not authorized') ||
      message.contains('current customer') ||
      message.contains('not currently authenticated') ||
      message.contains('token');
}
