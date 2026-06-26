import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/brand_lockup.dart';
import '../routes.dart';

/// Decluttered app bar per the design review: centered `ZOONZE` lockup, no cart
/// icon. The leading control is handled by the [Scaffold] automatically — a
/// hamburger on tab roots (drawer present, nothing to pop) and a back button on
/// pushed routes.
class ZoonzeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ZoonzeAppBar({super.key, this.showSearch = true});

  final bool showSearch;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      title: const BrandLockup(fontSize: 20),
      actions: [
        if (showSearch)
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push(AppRoutes.search),
          ),
      ],
    );
  }
}
