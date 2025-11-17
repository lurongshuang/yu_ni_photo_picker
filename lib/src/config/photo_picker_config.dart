import 'package:photo_manager/photo_manager.dart';

class PhotoPickerConfig {
  /// 是否多选
  final bool allowMultiple;

  /// 最大选择数
  final int maxAssets;

  /// 请求资源类型（图片/视频）
  final List<AssetType> requestType;

  // /// 排序方式
  // final OrderOptionType orderBy;

  // /// 是否升序
  // final bool orderAsc;

  /// 是否按日期分组
  final bool groupByDate;

  /// 是否按月份分组（开启日期分组时生效）
  final bool groupByMonth;

  /// 是否启用多分类Tab
  final bool enableCategoryTabs;

  // /// 是否显示预览按钮
  // final bool showPreviewButton;

  /// 是否显示原图开关
  final bool showOriginalToggle;

  /// 确认按钮文本
  final String confirmButtonText;

  const PhotoPickerConfig({
    this.allowMultiple = false,
    this.maxAssets = 5000,
    this.requestType = const [AssetType.image],
    // this.orderBy = OrderOptionType.createDate,
    // this.orderAsc = false,
    this.groupByDate = false,
    this.groupByMonth = false,
    this.enableCategoryTabs = false,
    // this.showPreviewButton = false,
    this.showOriginalToggle = false,
    this.confirmButtonText = '上传',
  });
}
