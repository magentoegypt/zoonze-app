import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:zoonze_app/core/error/failure.dart';
import 'package:zoonze_app/core/error/graphql_failure_mapper.dart';

void main() {
  group('mapOperationException', () {
    test('maps graphql-authorization category to auth', () {
      final exception = OperationException(
        graphqlErrors: [
          GraphQLError(
            message: 'Access denied',
            extensions: const {'category': 'graphql-authorization'},
          ),
        ],
      );
      expect(mapOperationException(exception).kind, FailureKind.auth);
    });

    test('maps an auth-flavoured message to auth', () {
      final exception = OperationException(
        graphqlErrors: [
          GraphQLError(message: "The current customer isn't authorized."),
        ],
      );
      expect(mapOperationException(exception).kind, FailureKind.auth);
    });

    test('maps a generic graphql error to server with detail', () {
      final exception = OperationException(
        graphqlErrors: [GraphQLError(message: 'Field "foo" not found.')],
      );
      final failure = mapOperationException(exception);
      expect(failure.kind, FailureKind.server);
      expect(failure.detail, 'Field "foo" not found.');
    });

    test('maps an empty exception to unknown', () {
      expect(
        mapOperationException(OperationException()).kind,
        FailureKind.unknown,
      );
    });

    test('maps a ServerException carrying an auth error (Magento 401) to auth', () {
      // Magento returns "Consumer key has expired" as HTTP 401 + an errors
      // payload — graphql wraps it in a ServerException, not a yielded response.
      final exception = OperationException(
        linkException: const ServerException(
          statusCode: 401,
          parsedResponse: Response(
            response: {},
            errors: [
              GraphQLError(
                message: 'Consumer key has expired',
                extensions: {'category': 'graphql-authentication'},
              ),
            ],
          ),
        ),
      );
      expect(mapOperationException(exception).kind, FailureKind.auth);
    });

    test('maps a ServerException carrying a generic error to server', () {
      final exception = OperationException(
        linkException: const ServerException(
          statusCode: 500,
          parsedResponse: Response(
            response: {},
            errors: [GraphQLError(message: 'Internal error')],
          ),
        ),
      );
      final failure = mapOperationException(exception);
      expect(failure.kind, FailureKind.server);
      expect(failure.detail, 'Internal error');
    });
  });
}
