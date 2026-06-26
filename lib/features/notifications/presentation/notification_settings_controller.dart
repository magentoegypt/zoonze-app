import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/notification_service.dart';
import '../../../core/storage/local_cache.dart';

/// Persisted key + topic for the promotions push opt-in.
const String kPromoPrefKey = 'notif_promotions';
const String kPromoTopic = 'promotions';

/// Whether promotional pushes are enabled (default on). Persisted locally and
/// reflected in the FCM topic subscription. Order pushes are token-targeted by
/// the backend and aren't a topic, so they're always delivered.
class NotificationSettings extends Notifier<bool> {
  @override
  bool build() =>
      ref.read(localCacheProvider).readString(kPromoPrefKey) != 'false';

  Future<void> setPromotions(bool enabled) async {
    state = enabled;
    await ref.read(localCacheProvider).writeString(kPromoPrefKey, '$enabled');
    if (enabled) {
      await NotificationService.instance.subscribeToTopic(kPromoTopic);
    } else {
      await NotificationService.instance.unsubscribeFromTopic(kPromoTopic);
    }
  }
}

final notificationSettingsProvider =
    NotifierProvider<NotificationSettings, bool>(NotificationSettings.new);

/// Applies the persisted topic subscriptions at startup (after FCM init). A
/// no-op when FCM is unavailable.
Future<void> applyNotificationTopics(LocalCache cache) async {
  if (cache.readString(kPromoPrefKey) != 'false') {
    await NotificationService.instance.subscribeToTopic(kPromoTopic);
  }
}
