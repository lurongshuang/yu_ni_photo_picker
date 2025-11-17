import 'package:flutter/material.dart';
import 'package:yuni_widget/yuni_widget.dart';

class ImagePlaceholder extends StatelessWidget {
  final double? width;
  final double? height;

  const ImagePlaceholder({super.key, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    final config = YuniWidgetConfig.instance;
    return Container(
      width: width,
      height: height,
      color: config.colors.onBackground.withValues(alpha: 0.05),
    );
  }
}

