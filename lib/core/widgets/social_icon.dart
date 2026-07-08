import 'package:flutter/material.dart';

/// Material icon proxy for a social-network key. Instagram/TikTok/Pinterest/X
/// have no native Material glyph, so the closest available icon is used — X
/// (formerly Twitter) shows the Material `close` glyph, which reads as its "✕".
IconData socialIconFor(String key) => switch (key) {
  'facebook' => Icons.facebook,
  'instagram' => Icons.camera_alt_outlined,
  'youtube' => Icons.smart_display_outlined,
  'tiktok' => Icons.music_note,
  'pinterest' => Icons.push_pin_outlined,
  'twitter' => Icons.close,
  _ => Icons.public,
};
