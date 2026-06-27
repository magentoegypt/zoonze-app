import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/brand_logo.dart';
import '../routes.dart';

/// Decluttered app bar per the design review: centered Z-mark + `ZOONZE` logo
/// lockup, no cart icon. The leading control is handled by the [Scaffold]
/// automatically — a hamburger on tab roots (drawer present, nothing to pop)
/// and a back button on pushed routes.
class ZoonzeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ZoonzeAppBar({super.key, this.showSearch = true});

  final bool showSearch;

  // Slightly taller than the Material default to seat the vertical lockup
  // (Z-mark over wordmark), matching the Figma 52 px header.
  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 60,
      centerTitle: true,
      title: const BrandLogo(height: 44),
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
