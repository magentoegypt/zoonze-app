import 'package:flutter/widgets.dart';

import '../../../core/widgets/network_image.dart';

/// The logical width the PDP hero paints at — the full screen width.
///
/// Both the gallery and anything that pre-warms the hero must decode at the
/// *same* width, or the two produce different [ImageCache] keys and the
/// pre-warm silently buys nothing. Keep this the single definition.
double pdpImageWidth(BuildContext context) => MediaQuery.sizeOf(context).width;

/// [pdpImageWidth] in physical pixels, for [ZoonzeImage.provider].
int? pdpImagePixels(BuildContext context) =>
    ZoonzeImage.decodePixels(context, pdpImageWidth(context));
