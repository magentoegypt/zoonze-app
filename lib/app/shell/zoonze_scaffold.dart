import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../routes.dart';
import 'menu_drawer.dart';
import 'zoonze_app_bar.dart';
import 'zoonze_bottom_nav.dart';

/// Standard chrome for primary screens: shared app bar + drawer + bottom nav.
/// Content screens place the [MarketingFooter] at the end of their own scroll
/// view; the 1st-group screens (splash/welcome/auth) do NOT use this scaffold.
///
/// Owns the Android hardware-back policy for its screens (QA): an open drawer
/// closes first; a pushed route pops; a non-Home tab root returns to Home
/// (instead of exiting the app); only Home itself exits.
class ZoonzeScaffold extends StatefulWidget {
  const ZoonzeScaffold({
    super.key,
    required this.currentTab,
    required this.body,
    this.showSearch = true,
    this.appBar,
    this.bottomBar,
  });

  final AppTab currentTab;
  final Widget body;
  final bool showSearch;
  final PreferredSizeWidget? appBar;

  /// Optional persistent bar pinned directly above the bottom nav (e.g. the PDP
  /// sticky Add-to-Cart bar). Null on most screens.
  final Widget? bottomBar;

  @override
  State<ZoonzeScaffold> createState() => _ZoonzeScaffoldState();
}

class _ZoonzeScaffoldState extends State<ZoonzeScaffold> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _onBack(bool didPop, Object? result) {
    if (didPop) return;
    // 1) Close the drawer if it's open.
    final scaffold = _scaffoldKey.currentState;
    if (scaffold?.isDrawerOpen ?? false) {
      scaffold!.closeDrawer();
      return;
    }
    // 2) A pushed route (PDP, orders, …) pops normally.
    if (context.canPop()) {
      context.pop();
      return;
    }
    // 3) A tab root other than Home returns to Home rather than exiting.
    if (widget.currentTab != AppTab.home) {
      context.go(AppRoutes.home);
      return;
    }
    // 4) Home root → let the system close the app.
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onBack,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: widget.appBar ?? ZoonzeAppBar(showSearch: widget.showSearch),
        drawer: const MenuDrawer(),
        body: widget.body,
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.bottomBar != null) widget.bottomBar!,
            ZoonzeBottomNav(current: widget.currentTab),
          ],
        ),
      ),
    );
  }
}
