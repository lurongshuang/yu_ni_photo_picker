import 'dart:ui';

import 'package:flutter/material.dart';

class BlurView extends StatelessWidget {
  final double intensity; // 模糊强度
  final Color? blurColor; // 模糊色彩
  final double blurRadius; // 模糊半径

  const BlurView({
    super.key,
    this.intensity = 1.0,
    this.blurColor,
    this.blurRadius = 10.0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blurRadius * intensity,
          sigmaY: blurRadius * intensity,
        ),
        child: Container(
          color: blurColor ?? Colors.black.withValues(alpha: 0.15),
        ),
      ),
    );
  }
}

