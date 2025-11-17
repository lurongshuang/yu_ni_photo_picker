import 'package:flutter/material.dart';
import '../utils/asset_util.dart';
import 'package:yuni_widget/yuni_widget.dart';

import '../constants/app_assets.dart';

///选中/为选中图标
class RadioIconWidget extends StatelessWidget {
  final bool selected;
  final double? size;
  final Color? color;

  const RadioIconWidget({
    super.key,
    this.selected = false,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AssetUtil.loadSvg(
      selected ? AppAssets.svg.radioSelected : AppAssets.svg.radio,
      width: size ?? 24,
      color: color,
    );
  }
}
