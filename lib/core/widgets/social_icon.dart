import 'package:flutter/material.dart';

/// Material icon proxy for a social-network key. Instagram/TikTok/Pinterest have
/// no native Material glyph, so the closest available icon is used.
IconData socialIconFor(String key) => switch (key) {
  'facebook' => Icons.facebook,
  'instagram' => Icons.camera_alt_outlined,
  'youtube' => Icons.ondemand_video,
  'tiktok' => Icons.music_note,
  'pinterest' => Icons.push_pin_outlined,
  'twitter' => Icons.alternate_email,
  _ => Icons.public,
};
