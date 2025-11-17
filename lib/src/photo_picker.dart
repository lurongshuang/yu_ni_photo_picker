import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'config/picker_file.dart';
import 'config/photo_picker_config.dart';
import 'page/photo_picker_page.dart';

class PhotoPicker {
  /// 单选
  static Future<PhotoPickerFile?> pickSingle({
    required BuildContext context,
    List<AssetType> requestType = const [AssetType.image],
    bool groupByDate = false,
    bool groupByMonth = false,
    bool enableCategoryTabs = false,
    // OrderOptionType orderBy = OrderOptionType.createDate,
    // bool orderAsc = false,
    // bool showPreviewButton = false,
    bool showOriginalToggle = false,
    String confirmButtonText = '上传',
  }) async {
    return Navigator.push<PhotoPickerFile?>(
      context,
      MaterialPageRoute(
        builder:
            (_) => PhotoPickerPage(
              config: PhotoPickerConfig(
                allowMultiple: false,
                requestType: requestType,
                groupByDate: groupByDate,
                groupByMonth: groupByMonth,
                enableCategoryTabs: enableCategoryTabs,
                // orderBy: orderBy,
                // orderAsc: orderAsc,
                // showPreviewButton: showPreviewButton,
                showOriginalToggle: showOriginalToggle,
                confirmButtonText: confirmButtonText,
              ),
            ),
      ),
    );
  }

  /// 多选
  static Future<List<PhotoPickerFile>> pickMultiple({
    required BuildContext context,
    List<AssetType> requestType = const [AssetType.image],
    bool groupByDate = false,
    bool groupByMonth = false,
    bool enableCategoryTabs = false,
    // OrderOptionType orderBy = OrderOptionType.createDate,
    // bool orderAsc = false,
    int maxAssets = 5000,
    // bool showPreviewButton = false,
    bool showOriginalToggle = false,
    String confirmButtonText = '上传',
  }) async {
    final result = await Navigator.push<List<PhotoPickerFile>>(
      context,
      MaterialPageRoute(
        builder:
            (_) => PhotoPickerPage(
              config: PhotoPickerConfig(
                allowMultiple: true,
                requestType: requestType,
                groupByDate: groupByDate,
                groupByMonth: groupByMonth,
                enableCategoryTabs: enableCategoryTabs,
                // orderBy: orderBy,
                // orderAsc: orderAsc,
                maxAssets: maxAssets,
                // showPreviewButton: showPreviewButton,
                showOriginalToggle: showOriginalToggle,
                confirmButtonText: confirmButtonText,
              ),
            ),
      ),
    );
    return result ?? [];
  }
}
