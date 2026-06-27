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
