/// 应用资源管理类
class AppAssets {
  AppAssets._();

  /// 图片资源
  static const Images images = Images();

  /// SVG资源
  static const Svg svg = Svg();

  /// 字体资源
  static const Fonts fonts = Fonts();
}

/// 图片资源类
class Images {
  const Images();

  /// 图片基础路径
  final String _basePath = 'packages/yu_ni_photo_picker/assets/image/';

  /// 获取图片完整路径
  String get(String name) => '$_basePath$name';

  /// 下箭头
  String get arrowIcon => 'arrow_icon.png';

  ///向下箭头
  String get bottomArrow => 'bottom_arrow.png';

  ///返回按钮
  String get leadingIcon => 'leading_icon.png';

  ///缩放按钮
  String get zoomIcon => 'zoom_icon.png';

  ///实时动态图
  // String get livePhotoIcon => 'live_photo_icon.png';
  ///实时动态图
  String get livePhotoIconOff => 'live_photo_icon_off.png';

  ///空数据
  String get iconEmpty => 'icon_empty.png';

  ///右侧进入
  String get rightArrowIcon => 'right_arrow_icon.png';

  /// 通知photo图标
  String get tabPhotoIcon => 'tab_photo_icon.png';
}

/// SVG资源类
class Svg {
  const Svg();

  /// SVG基础路径
  final String _basePath = 'packages/yu_ni_photo_picker/assets/svg/';

  /// 获取SVG完整路径
  String get(String name) => '$_basePath$name';

  ///选中图标
  String get radioSelected => 'svg_radio_selected.svg';

  ///未选中的图标
  String get radio => 'svg_radio.svg';

  ///实时动态图
  String get livePhotoSvg => 'live_photo.svg';

  String get livePhotoOffSvg => 'live_photo_off.svg';

  ///上传按钮
  String get uploadBtn => 'svg_upload.svg';
}

/// 字体资源类
class Fonts {
  const Fonts();

  /// 字体基础路径
  final String _basePath = 'packages/yu_ni_photo_picker/assets/font/';

  /// 获取字体完整路径
  String get(String name) => '$_basePath$name';

  /// 应用字体
  String get roboto => '${_basePath}Roboto-Regular.ttf';

  String get robotoMedium => '${_basePath}Roboto-Medium.ttf';

  String get robotoBold => '${_basePath}Roboto-Bold.ttf';
}
