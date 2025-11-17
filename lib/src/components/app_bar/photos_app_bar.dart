import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/app_assets.dart';
import '../../utils/asset_util.dart';
import '../../utils/device_type_util.dart' as dtu;
import 'package:yuni_widget/yuni_widget.dart';

///应用标题栏目
class PhotosAppBar extends YAppBar implements PreferredSizeWidget {
  final Color? bgColor;
  final Color? leadingColor;
  final SystemUiOverlayStyle? sysOverlayStyle;
  final bool showBottom;
  final TextStyle? textStyle;
  final double? popSize;
  final Widget? customTitleWidget;
  final bool titleCenter;
  final double? preferredHeight;

  /// 标题文本
  const PhotosAppBar({
    super.key,
    super.titleText,
    super.actions,
    this.bgColor,
    this.leadingColor,
    this.sysOverlayStyle,
    this.showBottom = true,
    this.textStyle,
    this.popSize,
    this.customTitleWidget,
    this.titleCenter = true,
    this.preferredHeight,
    super.shadowColor,
    super.elevation,
    super.surfaceTintColor,
    super.leading,
    super.toolbarHeight,
  });

  @override
  Widget build(BuildContext context) {
    final config = YuniWidgetConfig.instance;
    return PreferredSize(
      preferredSize: Size.fromHeight(preferredHeight ?? 46),
      child: YAppBar(
        shadowColor: super.shadowColor,
        elevation: super.elevation,
        surfaceTintColor: super.surfaceTintColor,
        backgroundColor: bgColor ?? backgroundColor,
        foregroundColor: config.colors.onBackground,
        toolbarHeight: super.toolbarHeight,
        systemUiOverlayStyle:
            sysOverlayStyle ??
            SystemUiOverlayStyle.dark.copyWith(
              statusBarBrightness: Brightness.light,
              statusBarIconBrightness: Brightness.dark,
              systemNavigationBarColor: bgColor ?? config.colors.background,
              systemNavigationBarIconBrightness: Brightness.dark,
            ),
        titleText: super.titleText,
        actions: super.actions,
        title: customTitleWidget,
        centerTitle: titleCenter,
        leading:
            super.leading ??
            Visibility(
              visible: Navigator.of(context).canPop(),
              child: YTapped(
                onTap: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                },
                child: Container(
                  color: Colors.transparent,
                  height: double.infinity,

                  child: Center(
                    child: IconButton(
                      icon: AssetUtil.loadAssetsImage(
                        AppAssets.images.leadingIcon,
                        width:
                            popSize ??
                            (dtu.DeviceTypeUtil.instance.isMobile ? 16 : 20),
                        height:
                            popSize ??
                            (dtu.DeviceTypeUtil.instance.isMobile ? 16 : 20),
                        color: leadingColor,
                      ),
                      onPressed:
                          onLeadingPressed ?? () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ),
            ),
        titleStyle: textStyle ?? config.textStyles.bodyLargeBold,
        bottom:
            dtu.DeviceTypeUtil.instance.deviceType == dtu.DeviceType.desktop &&
                    showBottom
                ? PreferredSize(
                  preferredSize: Size.zero,
                  child: YDivider(
                    color: config.colors.onBackground.withValues(alpha: 0.05),
                  ),
                )
                : null,
      ),
    );
  }
}
