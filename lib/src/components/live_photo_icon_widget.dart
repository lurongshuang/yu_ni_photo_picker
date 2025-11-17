import 'package:flutter/material.dart';
import '../components/blur_view.dart';
import '../constants/app_assets.dart';
import '../utils/asset_util.dart';
import 'package:yuni_widget/yuni_widget.dart';

///实况图片图标
class LivePhotoWidget extends StatelessWidget {
  final double? iconSize;

  const LivePhotoWidget({super.key, this.iconSize});

  @override
  Widget build(BuildContext context) {
    final config = YuniWidgetConfig.instance;
    return ClipRRect(
      borderRadius: config.radius.borderFull,
      child: Stack(
        children: [
          BlurView(),
          Container(
            padding: EdgeInsets.only(
              left: config.spacing.xs,
              right: config.spacing.xs + config.spacing.xs,
              top: config.spacing.xxs,
              bottom: config.spacing.xxs,
            ),
            decoration: BoxDecoration(
              color: config.colors.onSurface.withValues(alpha: 0.6),
              borderRadius: config.radius.borderFull,
            ),
            child: Row(
              children: [
                LivePhotoIconWidget(size: iconSize ?? 18),
                YSpacing.widthXxs(),
                YSpacing.widthXs(),
                YText.bodySmallRegular("LIVE", color: config.colors.onPrimary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LivePhotoIconWidget extends StatelessWidget {
  final double? size;
  final bool isOpen;

  const LivePhotoIconWidget({super.key, this.size = 18, this.isOpen = true});

  @override
  Widget build(BuildContext context) {
    if (isOpen) {
      return AssetUtil.loadAssetsImage(
        AppAssets.images.livePhotoIcon,
        width: size,
        height: size,
      );
    }
    return Icon(Icons.motion_photos_off, size: size);
    // return AssetUtil.loadAssetsImage(
    //   AppAssets.images.livePhotoIcon,
    //   width: size,
    //   height: size,
    // );
  }
}
