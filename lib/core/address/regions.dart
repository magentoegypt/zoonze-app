import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../error/graphql_failure_mapper.dart';
import '../graphql/graphql_client.dart';

/// A Magento system region (e.g. a UAE emirate). Magento requires a valid
/// `region_id` on an address when the country has system regions (AE does), so
/// address forms post this id rather than free-text `region`.
class RegionOption {
  const RegionOption({required this.id, required this.code, required this.name});

  final int id;
  final String code;
  final String name;
}

/// UAE-only storefront — the fixed address country. Region lists and the
/// address `country_code` both derive from this.
const String addressCountryCode = 'AE';

/// Fetches a country's system regions from the live schema
/// (`country(id:){ available_regions }`). Cross-cutting (checkout + account),
/// so it lives in core rather than a single feature.
class RegionsRepository {
  RegionsRepository(this._client);

  final GraphQLClient _client;

  static const String _query = r'''
query CountryRegions($id: String!) {
  country(id: $id) {
    id
    available_regions { id code name }
  }
}
''';

  Future<List<RegionOption>> fetchRegions(String countryCode) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(_query),
        variables: {'id': countryCode},
        // Region lists are effectively static — cache across the session.
        fetchPolicy: FetchPolicy.cacheFirst,
      ),
    );
    if (result.hasException) throw mapOperationException(result.exception!);
    final regions =
        (result.data?['country'] as Map<String, dynamic>?)?['available_regions']
            as List<dynamic>?;
    return (regions ?? const [])
        .whereType<Map<String, dynamic>>()
        .where((r) => r['id'] != null)
        .map(
          (r) => RegionOption(
            id: (r['id'] as num).toInt(),
            code: (r['code'] as String?) ?? '',
            name: (r['name'] as String?) ?? '',
          ),
        )
        .toList();
  }
}

final regionsRepositoryProvider = Provider<RegionsRepository>(
  (ref) => RegionsRepository(ref.watch(graphqlClientProvider)),
);

/// Regions for the storefront country (AE → the seven emirates). Cached for the
/// session and shared by every address form.
final regionsProvider = FutureProvider<List<RegionOption>>(
  (ref) => ref.watch(regionsRepositoryProvider).fetchRegions(addressCountryCode),
);
