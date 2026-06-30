import 'package:cupertino_http/cupertino_http.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;

import '../../features/auth/presentation/auth_controller.dart';
import '../config/app_config.dart';
import '../storage/secure_token_store.dart';
import '../store/store_controller.dart';
import 'resilience_link.dart';
import 'store_link.dart';

/// On iOS/macOS, route HTTP through `NSURLSession` (the same stack Safari uses)
/// instead of `dart:io`'s `HttpClient`. `dart:io` ignores the system proxy/VPN
/// and can hit TLS/connection edge cases that NSURLSession handles — which
/// presented as "all GraphQL failing on iOS while Safari + Android work".
/// Android keeps `dart:io` (it works and avoids an unnecessary native client).
http.Client _platformHttpClient() {
  if (defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    return CupertinoClient.fromSessionConfiguration(
      URLSessionConfiguration.defaultSessionConfiguration(),
    );
  }
  return http.Client();
}

/// Builds the GraphQL client with the link chain:
///   AuthLink (bearer when present) → StoreHeaderLink (dynamic `Store` header)
///   → ResilienceLink (retry transient queries + mid-session logout)
///   → HttpLink (terminating).
///
/// Exception → [Failure] mapping happens at the repository layer
/// (see `graphql_failure_mapper.dart`). Invalidate this provider on a
/// language/store switch to reset the cache and refetch with the new header.
final graphqlClientProvider = Provider<GraphQLClient>((ref) {
  final config = ref.watch(appConfigProvider);
  final tokenStore = ref.watch(secureTokenStoreProvider);

  // Set the stable User-Agent at the transport level too (not only via
  // StoreHeaderLink) so it is guaranteed on every request — without it, the
  // default `Dart/<ver> (dart:io)` UA goes out, which AWS WAF/bot rules are
  // likely to block (CLAUDE.md §7). The Store header stays dynamic in the link.
  final httpLink = HttpLink(
    config.graphqlEndpoint,
    defaultHeaders: {'User-Agent': config.userAgent},
    httpClient: _platformHttpClient(),
  );

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

  final resilienceLink = ResilienceLink(
    // Defer to a microtask so logout (which invalidates this very provider)
    // runs after the current response stream settles, never mid-emit.
    onAuthError: () => Future.microtask(
      () => ref.read(authControllerProvider.notifier).handleSessionExpired(),
    ),
  );

  final link = Link.from(<Link>[authLink, storeLink, resilienceLink, httpLink]);

  return GraphQLClient(
    link: link,
    cache: GraphQLCache(store: InMemoryStore()),
    // Disable graphql's built-in request timeout: its 5s default times out
    // mutations against the CloudFront/WAF-fronted endpoint, and its timeout
    // path double-completes the response completer when ResilienceLink retries
    // ("Bad state: Future already completed", graphql 5.2.4). ResilienceLink
    // owns the timeout instead (consumed via `await for`, so no double-complete).
    queryRequestTimeout: null,
    defaultPolicies: DefaultPolicies(
      query: Policies(fetch: FetchPolicy.networkOnly),
    ),
  );
});
