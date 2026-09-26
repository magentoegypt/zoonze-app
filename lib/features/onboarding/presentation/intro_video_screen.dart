import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../l10n/l10n.dart';

/// Asset path of the first-launch intro. See `assets/video/README.md` for the
/// encode it must be kept to.
const String kIntroVideoAsset = 'assets/video/app_intro.mp4';

/// The video's own background red, sampled from its corner (constant for the
/// whole clip). Deliberately **not** `AppColors.brandPrimary` (#9E1B3F): the
/// two are visibly different, and this colour is what makes the letterbox
/// bands indistinguishable from the frame itself.
const Color _kIntroBackdrop = Color(0xFF8F2221);

/// The first-launch intro video (CL042-DEV41), shown once in place of the
/// static launch splash.
///
/// Rendered by [LaunchSplashScreen] rather than owning a route of its own, so
/// the very first frame after the native splash is already this video — routing
/// to it would flash the static splash first, and the video ends on the same
/// logo that splash shows.
///
/// Contract with the caller:
/// * [onFinished] fires exactly once — on natural end, on Skip, or on a failure
///   to initialise. Startup must never hang behind a video, so the caller keeps
///   its own timeout as a backstop.
/// * [onFailed] fires instead of any playback when the asset can't be decoded,
///   so the caller can fall back to the static splash rather than hold a black
///   frame. This is the path that bricks first launch when it's left untested.
class IntroVideoView extends StatefulWidget {
  const IntroVideoView({
    super.key,
    required this.onFinished,
    required this.onFailed,
  });

  /// Playback reached its end, or the user skipped.
  final VoidCallback onFinished;

  /// The asset could not be initialised — nothing was shown.
  final VoidCallback onFailed;

  @override
  State<IntroVideoView> createState() => _IntroVideoViewState();
}

class _IntroVideoViewState extends State<IntroVideoView> {
  VideoPlayerController? _controller;
  bool _ready = false;

  /// Guards [widget.onFinished] — end-of-playback and Skip can race.
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final controller = VideoPlayerController.asset(kIntroVideoAsset);
    _controller = controller;
    try {
      await controller.initialize();
      if (!mounted) return;
      // Silent by design — the supplied master's audio track is digital
      // silence. Muting explicitly means a future re-encode that *does* carry
      // audio can't surprise a user into an unexpected noise at launch.
      await controller.setVolume(0);
      controller.addListener(_watchForEnd);
      await controller.play();
      setState(() => _ready = true);
    } on Object {
      // Missing asset, unsupported codec, decoder exhaustion — any of these
      // must fall through to the normal splash, not strand the user.
      if (mounted) widget.onFailed();
    }
  }

  void _watchForEnd() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final value = controller.value;
    if (value.position >= value.duration && !value.isPlaying) _finish();
  }

  void _finish() {
    if (_done) return;
    _done = true;
    widget.onFinished();
  }

  @override
  void dispose() {
    _controller?.removeListener(_watchForEnd);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = _controller;
    return Scaffold(
      backgroundColor: _kIntroBackdrop,
      body: Stack(
        children: [
          if (_ready && controller != null)
            // Contain, not cover. The intro is 9:16 and its copy runs nearly
            // edge to edge, so covering a 19.5:9 phone cropped ~11% off each
            // side and cut the words in half ("HURRY BEFORE" lost both its
            // outer letters — QA, 2026-09-26). Letterboxing against the
            // video's own background colour costs nothing visible, because the
            // sunburst's edges are a flat red that the bands match exactly.
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              ),
            ),
          // Skip is present from the first frame, never on a delay: a promo a
          // returning user can't dismiss is the first thing they meet.
          PositionedDirectional(
            top: 0,
            end: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(0, 8, 12, 0),
                child: TextButton(
                  onPressed: _finish,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.35),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    l10n.introSkip,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
