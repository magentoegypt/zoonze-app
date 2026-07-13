/// Upgrades a Magento media URL to HTTPS.
///
/// The store's `base_media_url` is `http://zoonze.com/media/`, but the same
/// media is served over HTTPS (`secure_base_url`). Android blocks cleartext
/// http by default, so image URLs from GraphQL must be upgraded to https before
/// loading. Already-secure or relative/data URLs are returned unchanged.
String? httpsMediaUrl(String? url) {
  if (url == null || url.isEmpty) return url;
  if (url.startsWith('http://')) return 'https://${url.substring(7)}';
  return url;
}

/// Resolves a possibly-relative media path (e.g. a banner `image_url` from the
/// backend) against the store's [base] media URL, upgrading to HTTPS. Absolute
/// URLs pass through; empty input (or an empty base for a relative path) yields
/// an empty string so callers degrade gracefully.
String resolveMediaUrl(String? raw, String base) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return '';
  if (value.startsWith('http')) return httpsMediaUrl(value) ?? '';
  if (base.isEmpty) return '';
  final b = base.endsWith('/') ? base : '$base/';
  final path = value.startsWith('/') ? value.substring(1) : value;
  return httpsMediaUrl('$b$path') ?? '';
}
