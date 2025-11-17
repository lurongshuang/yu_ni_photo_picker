import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../components/image_view/image_placeholder.dart';
import '../constants/app_assets.dart';

/// 资源工具类，提供便捷的资源加载方法
/// 注意：优先使用YuniWidget库中的组件和资源管理功能
class AssetUtil {
  AssetUtil._();

  /// 加载项目图片资源
  /// (优先使用YuniAssets中的资源)
  static Image loadAssetsImage(
    String name, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Color? color,
  }) {
    try {
      return Image.asset(
        AppAssets.images.get(name),
        width: width,
        height: height,
        fit: fit,
        color: color,
        errorBuilder: (
          BuildContext context,
          Object error,
          StackTrace? stackTrace,
        ) {
          return Stack(children: [ImagePlaceholder()]);
        },
      );
    } catch (e) {
      debugPrint(
        'Warning: Using local asset instead of YuniWidget asset: $name',
      );
      return Image.asset(
        AppAssets.images.get(name),
        width: width,
        height: height,
        fit: fit,
      );
    }
  }

  /// 加载SVG资源
  /// (优先使用YuniAssets中的资源)
  static SvgPicture loadSvg(
    String name, {
    double? width,
    double? height,
    Color? color,
  }) {
    return SvgPicture.asset(
      AppAssets.svg.get(name),
      width: width,
      height: height,
      colorFilter:
          color != null ? ColorFilter.mode(color, BlendMode.srcIn) : null,
    );
  }
}

