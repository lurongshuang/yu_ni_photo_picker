import 'package:flutter/material.dart';
import 'package:yuni_widget/yuni_widget.dart';

class ImageError extends StatelessWidget {
  const ImageError({super.key});

  @override
  Widget build(BuildContext context) {
    final config = YuniWidgetConfig.instance;
    return Container(
      decoration: BoxDecoration(
        color: config.colors.background.withValues(alpha: 0.5),
        borderRadius: config.radius.borderSm,
      ),
      child: Icon(
        Icons.broken_image_outlined,
        size: YuniWidgetConfig.instance.textStyles.headingLarge,
        color: config.colors.onBackground.withValues(alpha: 0.1),
      ),
    );
  }
}

