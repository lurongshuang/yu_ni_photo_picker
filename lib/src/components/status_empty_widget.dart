import 'package:flutter/material.dart';
import '../constants/app_assets.dart';
import '../utils/asset_util.dart';
import 'package:yuni_widget/yuni_widget.dart';

///无数据
class StatusEmptyWidget extends StatelessWidget {
  final String? text;
  const StatusEmptyWidget({
    super.key,
    this.text,
  });

  @override
  Widget build(BuildContext context) {
    final config = YuniWidgetConfig.instance;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AssetUtil.loadAssetsImage(
            AppAssets.images.iconEmpty,
            width: config.spacing.mega * 2,
            height: config.spacing.mega * 2,
          ),
          YSpacing.heightLg(),
          YText.bodyMediumRegular(
            text ?? '暂无数据',
            color: config.colors.onBackground.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}

