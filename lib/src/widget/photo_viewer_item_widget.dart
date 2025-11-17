import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_view/photo_view.dart';
import 'photo_viewer_image_widget.dart';
import 'photo_viewer_video_widget.dart';

/// 图片查看器项目组件
class PhotoViewerItemWidget extends StatelessWidget {
  final AssetEntity asset;
  final PhotoViewScaleStateController? scaleStateController;
  final PhotoViewImageScaleEndCallback? onScaleStateChanged;

  // final VoidCallback? onTap;

  const PhotoViewerItemWidget({
    super.key,
    required this.asset,
    this.scaleStateController,
    this.onScaleStateChanged,
    // this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 根据资产类型选择不同的显示组件
    if (asset.type == AssetType.video) {
      return PhotoViewerVideoWidget(
        asset: asset,
        // , onTap: onTap
      );
    } else {
      return PhotoViewerImageWidget(
        asset: asset,
        scaleStateController: scaleStateController,
        onScaleStateChanged: onScaleStateChanged,
        // onTap: onTap,
      );
    }
  }
}

