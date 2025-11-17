import 'package:flutter/material.dart';
import 'package:yuni_widget/yuni_widget.dart';

enum PlayButtonSize { small, medium, large }

class PlayButtonOverlayWidget extends StatelessWidget {
  final PlayButtonSize size;

  const PlayButtonOverlayWidget({super.key, this.size = PlayButtonSize.medium});

  double _getWidgetSize(YuniWidgetConfig config) {
    switch (size) {
      case PlayButtonSize.small:
        return config.spacing.xl;
      case PlayButtonSize.medium:
        return config.spacing.xxl + config.spacing.xs;
      case PlayButtonSize.large:
        return config.spacing.xxxl;
    }
  }

  double _getIconSize(YuniWidgetConfig config) {
    switch (size) {
      case PlayButtonSize.small:
        return config.spacing.lg;
      case PlayButtonSize.medium:
        return config.spacing.xxl;
      case PlayButtonSize.large:
        return config.spacing.xxl + config.spacing.md;
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = YuniWidgetConfig.instance;

    // 获取计算后的组件尺寸和图标尺寸
    final widgetSize = _getWidgetSize(config);
    final iconSize = _getIconSize(config);

    return Container(
      decoration: BoxDecoration(
        borderRadius: config.radius.borderFull,
        color: config.colors.onBackground.withValues(alpha: 0.7),
        // border: Border.all(color: config.colors.background, width: 1),
      ),
      child: SizedBox(
        width: widgetSize,
        height: widgetSize,
        child: Stack(
          children: [
            Center(
              child: Icon(
                Icons.play_arrow_rounded,
                color: config.colors.surface,
                size: iconSize,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

