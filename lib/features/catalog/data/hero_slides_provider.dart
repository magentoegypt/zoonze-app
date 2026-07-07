import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../core/graphql/graphql_client.dart';
import '../../../core/store/store_controller.dart';
import '../domain/hero_slide.dart';

const String _query = r'''
query HeroSlides {
  heroSlides {
    slide_id
    position
    eyebrow
    title
    description
    cta_label
    cta_url
    image_url
    video_url
  }
}
''';

/// Admin-managed home hero slides (MagentoEgypt_Beauty), sorted by position.
/// Degrades to an empty list on error/absence so the home falls back to its
/// static hero — never a broken or fabricated banner.
final heroSlidesProvider = FutureProvider.autoDispose<List<HeroSlide>>((
  ref,
) async {
  ref.watch(storeControllerProvider.select((s) => s.activeStoreCode));
  final client = ref.watch(graphqlClientProvider);
  try {
    final result = await client.query(
      QueryOptions(document: gql(_query), fetchPolicy: FetchPolicy.networkOnly),
    );
    if (result.hasException) return const <HeroSlide>[];
    final list = result.data?['heroSlides'] as List<dynamic>?;
    if (list == null) return const <HeroSlide>[];
    final slides =
        list.whereType<Map<String, dynamic>>().map(_parse).toList()
          ..sort((a, b) => a.position.compareTo(b.position));
    return slides;
  } catch (_) {
    return const <HeroSlide>[];
  }
});

HeroSlide _parse(Map<String, dynamic> j) => HeroSlide(
  slideId: (j['slide_id'] as num?)?.toInt() ?? 0,
  position: (j['position'] as num?)?.toInt() ?? 0,
  eyebrow: (j['eyebrow'] as String?)?.trim() ?? '',
  title: (j['title'] as String?)?.trim() ?? '',
  description: (j['description'] as String?)?.trim() ?? '',
  ctaLabel: (j['cta_label'] as String?)?.trim() ?? '',
  ctaUrl: (j['cta_url'] as String?)?.trim() ?? '',
  imageUrl: (j['image_url'] as String?)?.trim() ?? '',
  videoUrl: (j['video_url'] as String?)?.trim() ?? '',
);

/// Maps a Magento category `cta_url` to the in-app category route's UID, or null
/// if it isn't a category URL. Magento's category UID is base64 of the numeric
/// id, so `.../catalog/category/view/id/5/` → `base64("5")`.
String? categoryUidFromUrl(String url) {
  final match = RegExp(r'/category/view/id/(\d+)').firstMatch(url);
  if (match == null) return null;
  return base64.encode(utf8.encode(match.group(1)!));
}

/// Extracts a product `url_key` from a storefront product URL — the last
/// non-empty path segment with a trailing `.html` stripped — so a hero CTA that
/// points at a product page can open the in-app PDP instead of the browser.
/// Returns null when there's nothing usable.
String? productUrlKeyFromStoreUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return null;
  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segments.isEmpty) return null;
  var last = segments.last;
  if (last.toLowerCase().endsWith('.html')) {
    last = last.substring(0, last.length - 5);
  }
  return last.isEmpty ? null : last;
}
