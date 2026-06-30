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
///
/// The stable [userAgent] is pinned at the session-configuration level
/// (`httpAdditionalHeaders`) so the allow-listed UA reaches AWS WAF on *every*
/// request — otherwise NSURLSession sends its default `app/version CFNetwork/…
/// Darwin/…` UA, which the WAF blocks (returns an HTML page → `service` error).
http.Client _platformHttpClient(String userAgent) {
  if (defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    final configuration =
        URLSessionConfiguration.defaultSessionConfiguration()
          ..httpAdditionalHeaders = {'User-Agent': userAgent};
    return CupertinoClient.fromSessionConfiguration(configuration);
  }
  return http.Client();
}

/// Diagnostic probe: hits the GraphQL endpoint with the **platform** HTTP client
/// (NSURLSession on iOS) and the app's real headers, returning the raw status,
/// content-type and a body snippet. Bypasses graphql_flutter so we can see
/// exactly what the edge returns on the actual iOS transport — JSON vs a
/// WAF/CloudFront HTML page. Surfaced on the diagnostics screen.
Future<({int status, String contentType, String body})> rawTransportProbe(
  AppConfig config,
  String storeCode,
) async {
  final client = _platformHttpClient(config.userAgent);
  try {
    final response = await client.post(
      Uri.parse(config.graphqlEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': config.userAgent,
        'Store': storeCode,
      },
      body: '{"query":"{storeConfig{store_code}}"}',
    );
    final body = response.body;
    return (
      status: response.statusCode,
      contentType: response.headers['content-type'] ?? '—',
      body: body.length > 600 ? '${body.substring(0, 600)}…' : body,
    );
  } finally {
    client.close();
  }
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
    httpClient: _platformHttpClient(config.userAgent),
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
