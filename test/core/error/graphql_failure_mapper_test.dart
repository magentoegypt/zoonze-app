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
  });
}
