import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/graphql_failure_mapper.dart';
import '../../../core/graphql/graphql_client.dart';
import '../domain/customer.dart';
import 'auth_queries.dart';

class AuthRepository {
  AuthRepository(this._client);

  final GraphQLClient _client;

  /// Returns a customer token. Throws [Failure] (auth) on bad credentials.
  Future<String> login(String email, String password) async {
    final data = await _mutate(AuthQueries.generateToken, {
      'email': email,
      'password': password,
    });
    final token =
        (data['generateCustomerToken'] as Map<String, dynamic>?)?['token']
            as String?;
    if (token == null || token.isEmpty) {
      throw const Failure(FailureKind.auth);
    }
    return token;
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    await _mutate(AuthQueries.createCustomer, {
      'input': <String, dynamic>{
        'firstname': firstName,
        'lastname': lastName,
        'email': email,
        'password': password,
      },
    });
  }

  /// Best-effort token revocation; failures are swallowed so logout always
  /// proceeds to clear local state.
  Future<void> revokeToken() async {
    try {
      await _mutate(AuthQueries.revokeToken, const {});
    } on Object {
      // ignore
    }
  }

  Future<void> requestPasswordReset(String email) async {
    await _mutate(AuthQueries.requestPasswordReset, {'email': email});
  }

  Future<Customer> fetchCustomer() async {
    final data = await _query(AuthQueries.customer);
    final customer = data['customer'] as Map<String, dynamic>?;
    if (customer == null) throw const Failure(FailureKind.auth);
    return Customer.fromJson(customer);
  }

  Future<Map<String, dynamic>> _mutate(
    String document,
    Map<String, dynamic> variables,
  ) async {
    try {
      final result = await _client.mutate(
        MutationOptions(
          document: gql(document),
          variables: variables,
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) {
        throw mapOperationException(result.exception!);
      }
      return result.data ?? const <String, dynamic>{};
    } on Failure {
      rethrow;
    } catch (error) {
      throw Failure(FailureKind.unknown, detail: error.toString());
    }
  }

  Future<Map<String, dynamic>> _query(String document) async {
    try {
      final result = await _client.query(
        QueryOptions(
          document: gql(document),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) {
        throw mapOperationException(result.exception!);
      }
      return result.data ?? const <String, dynamic>{};
    } on Failure {
      rethrow;
    } catch (error) {
      throw Failure(FailureKind.unknown, detail: error.toString());
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(graphqlClientProvider)),
);
