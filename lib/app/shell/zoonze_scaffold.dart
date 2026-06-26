import 'package:flutter/material.dart';

import '../routes.dart';
import 'menu_drawer.dart';
import 'zoonze_app_bar.dart';
import 'zoonze_bottom_nav.dart';

/// Standard chrome for primary screens: shared app bar + drawer + bottom nav.
/// Content screens place the [MarketingFooter] at the end of their own scroll
/// view; the 1st-group screens (splash/welcome/auth) do NOT use this scaffold.
class ZoonzeScaffold extends StatelessWidget {
  const ZoonzeScaffold({
    super.key,
    required this.currentTab,
    required this.body,
    this.showSearch = true,
    this.appBar,
  });

  final AppTab currentTab;
  final Widget body;
  final bool showSearch;
  final PreferredSizeWidget? appBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar ?? ZoonzeAppBar(showSearch: showSearch),
      drawer: const MenuDrawer(),
      body: body,
      bottomNavigationBar: ZoonzeBottomNav(current: currentTab),
    );
  }
}
