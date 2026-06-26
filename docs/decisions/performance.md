# Decision — Performance polish (Phase 5)

A focused pass; the catalog lists were already lazy, so the win was image memory.

## Applied
- **Image decode sizing.** Every `CachedNetworkImage` / `Image.asset` now decodes
  at the on-screen size (× device pixel ratio), not the source's full resolution
  — the main memory/jank win across product grids:
  - `ProductCard` thumbnail — `memCacheWidth` from a `LayoutBuilder` (exact cell width).
  - PDP gallery — `memCacheWidth` from the screen width.
  - Cart thumbnail — `memCacheWidth` for the fixed 72pt size.
  - Home banner (`Image.asset`) — `cacheWidth` from the screen width.

## Already optimal (verified, left as-is)
- **PLP** uses a lazy `SliverGrid` + `SliverChildBuilderDelegate`; **home** uses
  `ListView.separated` / `GridView.builder`. The framework adds repaint
  boundaries to builder-delegated children by default.
- **Bottom-nav badges** scope rebuilds with `cartControllerProvider.select((s) => s.itemCount)`.
- Screen-level `ListView(...)`s (account, checkout, notifications, etc.) hold a
  small bounded set of children — converting to builders would add complexity
  for no measurable gain.

## Not done (out of app-side scope / low value)
- Home "Featured" uses a `shrinkWrap` `GridView.builder` (builds all featured
  items); the set is small, so left as-is.
- Startup/runtime profiling on a device (DevTools timeline) is a developer step
  on real hardware.
