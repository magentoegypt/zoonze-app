import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../config/app_config.dart';
import '../storage/secure_token_store.dart';
import '../store/store_controller.dart';
import 'store_link.dart';

/// Builds the GraphQL client with the link chain:
///   AuthLink (bearer when present) → StoreHeaderLink (dynamic `Store` header)
///   → HttpLink (terminating).
///
/// Exception → [Failure] mapping happens at the repository layer
/// (see `graphql_failure_mapper.dart`). Invalidate this provider on a
/// language/store switch to reset the cache and refetch with the new header.
final graphqlClientProvider = Provider<GraphQLClient>((ref) {
  final config = ref.watch(appConfigProvider);
  final tokenStore = ref.watch(secureTokenStoreProvider);

  final httpLink = HttpLink(config.graphqlEndpoint);

  final authLink = AuthLink(
    getToken: () async {
      final token = await tokenStore.read();
      return token == null ? null : 'Bearer $token';
    },
  );

  final storeLink = StoreHeaderLink(
    storeCode: () => ref.read(storeControllerProvider).activeStoreCode,
    userAgent: config.userAgent,
  );

  final link = Link.from(<Link>[authLink, storeLink, httpLink]);

  return GraphQLClient(
    link: link,
    cache: GraphQLCache(store: InMemoryStore()),
    defaultPolicies: DefaultPolicies(
      query: Policies(fetch: FetchPolicy.networkOnly),
    ),
  );
});
