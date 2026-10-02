import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zoonze_app/core/util/edge_to_edge.dart';

/// Play Console flagged release 125 for being edge-to-edge only where Android
/// enforces it. The call that fixes that is one line in bootstrap and invisible
/// in the widget tree, so these pin the message that actually goes to the
/// platform — and pin that it is Flutter's mode channel rather than androidx's
/// `enableEdgeToEdge()`, which would reintroduce the deprecated bar-colour APIs
/// Play flagged on the very same release.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          calls.add(call);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test('asks Android for edge-to-edge', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await enableEdgeToEdge();
    expect(calls, hasLength(1));
    expect(calls.single.method, 'SystemChrome.setEnabledSystemUIMode');
    // Not SystemChrome.setEnabledSystemUIOverlays, and not a style call —
    // those are the ones that reach Window.setStatusBarColor.
    expect(calls.single.arguments, 'SystemUiMode.edgeToEdge');
  });

  test('leaves iOS alone, which is edge-to-edge already', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await enableEdgeToEdge();
    expect(calls, isEmpty);
  });
}
