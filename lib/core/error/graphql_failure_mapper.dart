import 'package:graphql_flutter/graphql_flutter.dart';

import 'failure.dart';

/// Maps a graphql_flutter [OperationException] to a domain [Failure].
///
/// Kept defensive (string-based link inspection) so it stays robust across
/// graphql_flutter point releases that rename concrete exception classes.
Failure mapOperationException(OperationException exception) {
  final linkException = exception.linkException;
  if (linkException != null) {
    final text = linkException.toString().toLowerCase();
    // A non-JSON / HTML body (WAF, CloudFront error page, maintenance) surfaces
    // as a parse/format failure rather than a clean GraphQL error.
    if (text.contains('format') ||
        text.contains('parse') ||
        text.contains('html') ||
        text.contains('<!doctype')) {
      return const Failure(FailureKind.service);
    }
    return const Failure(FailureKind.network);
  }

  final graphqlErrors = exception.graphqlErrors;
  if (graphqlErrors.isNotEmpty) {
    final isAuth = graphqlErrors.any(_isAuthError);
    if (isAuth) return const Failure(FailureKind.auth);
    return Failure(FailureKind.server, detail: graphqlErrors.first.message);
  }

  return const Failure(FailureKind.unknown);
}

bool _isAuthError(GraphQLError error) {
  final category = error.extensions?['category'];
  if (category == 'graphql-authorization' || category == 'graphql-authentication') {
    return true;
  }
  final message = error.message.toLowerCase();
  return message.contains('not authorized') ||
      message.contains('current customer') ||
      message.contains('not currently authenticated') ||
      message.contains('token');
}
