import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';

/// Disk cache keeps the original; decoded thumbnails fit their physical slot.
/// Quantized sizes avoid a new memory-cache entry for each layout pixel.
class ProductThumbnail extends StatelessWidget {
  const ProductThumbnail(
      {super.key, required this.url, this.alignment = Alignment.center});
  final String url;
  final Alignment alignment;

  static int decodeSize(double logicalPixels, double pixelRatio) =>
      ((logicalPixels * pixelRatio / 64).ceil() * 64).clamp(64, 1024);

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final ratio = MediaQuery.devicePixelRatioOf(context);
        final width =
            decodeSize(box.hasBoundedWidth ? box.maxWidth : 200, ratio);
        final height =
            decodeSize(box.hasBoundedHeight ? box.maxHeight : 200, ratio);
        if (url.isEmpty) {
          return const Icon(Icons.image_outlined,
              color: AppColors.secondaryText);
        }
        return Image(
          image: ResizeImage(CachedNetworkImageProvider(url),
              width: width, height: height, policy: ResizeImagePolicy.fit),
          fit: BoxFit.contain,
          alignment: alignment,
          frameBuilder: (context, child, frame, synchronous) {
            if (synchronous || MediaQuery.disableAnimationsOf(context)) {
              return child;
            }
            return AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: AppMotion.feedback,
                curve: AppMotion.curve,
                child: child);
          },
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.image_outlined, color: AppColors.secondaryText),
        );
      });
}
