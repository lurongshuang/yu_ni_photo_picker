import 'package:flutter/material.dart';
import '../utils/asset_util.dart';
import 'package:yuni_widget/yuni_widget.dart';

import '../constants/app_assets.dart';

///选中/为选中图标
class RadioIconWidget extends StatelessWidget {
  final bool selected;
  final double? size;

  ///为选中时，是否为透明的选择框
  final bool isTransparentUnSelect;

  const RadioIconWidget({
    super.key,
    this.selected = false,
    this.size,
    this.isTransparentUnSelect = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isTransparentUnSelect && !selected) {
      final config = YuniWidgetConfig.instance;
      return Center(
        child: Container(
          width: size ?? 24,
          height: size ?? 24,
          decoration: BoxDecoration(
            border: Border.all(
              color: config.colors.background.withValues(alpha: 0.7),
              width: 1.5,
            ),
            borderRadius: config.radius.borderFull,
          ),
        ),
      );
    }
    return AssetUtil.loadSvg(
      selected ? AppAssets.svg.radioSelected : AppAssets.svg.radio,
      width: size ?? 24,
    );
  }
}

