import 'package:flutter/material.dart';
import '../model/date_grouped_asset.dart';
import '../model/photo_picker_state.dart';
import '../config/album_settings.dart';
import '../config/photo_picker_config.dart';
import 'drag_selectable_grid_view.dart';
import '../widget/asset_grid/asset_grid_data_structure.dart' as ag;
import '../widget/asset_grid/asset_grid_view.dart' as ag;
import 'package:vs_scrollbar/vs_scrollbar.dart';

/// 支持日期分组的 GridView 组件
class DateGroupedGridView extends StatelessWidget {
  /// 资源列表
  final List<ChoiceAssetEntity> assets;

  /// 是否按日期分组
  final bool groupByDate;

  /// 是否按月份分组
  final bool groupByMonth;

  /// 排序方式
  final AlbumSortType sortType;

  /// 网格列数
  final int crossAxisCount;

  /// 列间距
  final double crossAxisSpacing;

  /// 行间距
  final double mainAxisSpacing;

  /// GridView 的 padding
  final EdgeInsetsGeometry? padding;

  /// 滚动控制器
  final ScrollController? controller;

  /// 是否启用滑动选择
  final bool enableDragSelection;

  /// 选择控制器
  final DragSelectionController? selectionController;

  /// 选择模式
  final SelectionMode selectionMode;

  /// 最大选择数量
  final int maxSelection;

  /// 滑动选择开始回调
  final void Function(int index)? onDragSelectionStart;

  /// 滑动选择更新回调
  final void Function(int index)? onDragSelectionUpdate;

  /// 滑动选择结束回调
  final void Function()? onDragSelectionEnd;

  /// 选中状态变化回调
  final void Function(Set<int> selectedIndices)? onSelectionChanged;

  /// 单个项目选择状态变化回调
  final void Function(int index, bool isSelected)? onItemSelectionChanged;

  /// 获取指定索引item的选中状态
  final bool Function(int index)? isItemSelected;

  /// 点击item回调
  final void Function(int index)? onItemTap;

  /// 长按item回调
  final void Function(int index)? onItemLongPress;

  /// 布局格式
  final AlbumLayoutFormat layoutFormat;

  /// 配置
  final PhotoPickerConfig config;

  /// 是否还有更多数据
  final bool hasMore;

  /// 是否正在加载更多
  final bool isLoadingMore;

  const DateGroupedGridView({
    super.key,
    required this.assets,
    this.groupByDate = true,
    this.groupByMonth = false,
    this.sortType = AlbumSortType.shootTime,
    this.crossAxisCount = 3,
    this.crossAxisSpacing = 2.0,
    this.mainAxisSpacing = 2.0,
    this.padding,
    this.controller,
    this.enableDragSelection = true,
    this.selectionController,
    this.selectionMode = SelectionMode.multiple,
    this.maxSelection = 999999,
    this.onDragSelectionStart,
    this.onDragSelectionUpdate,
    this.onDragSelectionEnd,
    this.onSelectionChanged,
    this.onItemSelectionChanged,
    this.isItemSelected,
    this.onItemTap,
    this.onItemLongPress,
    this.layoutFormat = AlbumLayoutFormat.gridView,
    required this.config,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  @override
  Widget build(BuildContext context) {
    // 按日期分组
    final groupedAssets = DateGroupUtil.groupAssetsByDate(
      assets: assets,
      sortType: sortType,
      groupByDate: groupByDate,
      groupByMonth: groupByMonth,
    );

    // 计算分段信息（维护资产全局起始索引，避免日期头影响索引映射）
    final List<_SectionInfo> sections = [];
    int assetStartIndexCounter = 0;

    for (final group in groupedAssets) {
      if (groupByDate && group.dateKey.isNotEmpty) {
        // 日期标题占1个位置
        sections.add(
          _SectionInfo(
            type: _ItemType.dateHeader,
            dateLabel: group.dateLabel,
            itemCount: 1,
          ),
        );
      }

      // 该日期下的资源
      sections.add(
        _SectionInfo(
          type: _ItemType.asset,
          assets: group.assets,
          assetStartIndex: assetStartIndexCounter,
          itemCount: group.assets.length,
        ),
      );
      assetStartIndexCounter += group.assets.length;
    }

    final groupBy =
        groupByDate
            ? (groupByMonth ? ag.GroupAssetsBy.month : ag.GroupAssetsBy.day)
            : ag.GroupAssetsBy.none;
    final renderList = ag.RenderList.fromAssets(assets, groupBy);
    final idToIndex = <String, int>{};
    for (int i = 0; i < assets.length; i++) {
      idToIndex[assets[i].asset.id] = i;
    }
    return VsScrollbar(
      controller: controller,
      child: ag.AssetGridView(
        renderList: renderList,
        assetsPerRow: crossAxisCount,
        margin: crossAxisSpacing,
        controller: controller,
        config: config,
        padding: padding,
        selectionActive: selectionMode == SelectionMode.multiple,
        onRefresh: null,
        listener: (active, selectedIds) {
          final indices = <int>{};
          for (final id in selectedIds) {
            final idx = idToIndex[id];
            if (idx != null) indices.add(idx);
          }
          onSelectionChanged?.call(indices);
        },
        onItemTap: (globalIndex) => onItemTap?.call(globalIndex),
        onItemLongPress: (globalIndex) => onItemLongPress?.call(globalIndex),
      ),
    );
  }

  // /// 构建日期标题
  // Widget _buildDateHeader(BuildContext context, String dateLabel) {
  //   final config = YuniWidgetConfig.instance;
  //   return Container(
  //     padding: EdgeInsets.symmetric(
  //       horizontal: 16.w,
  //       vertical: 8.h,
  //     ),
  //     color: config.colors.surface,
  //     child: Row(
  //       children: [
  //         YText(
  //           dateLabel,
  //           style: config.textStyles.bodyLargeBold.copyWith(
  //             color: config.colors.onSurface,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}

/// 项目类型
enum _ItemType {
  dateHeader, // 日期标题
  asset, // 资源项
}

/// 分组信息
class _SectionInfo {
  final _ItemType type;
  final String? dateLabel;
  final List<ChoiceAssetEntity>? assets;
  final int? assetStartIndex;
  final int itemCount;

  _SectionInfo({
    required this.type,
    this.dateLabel,
    this.assets,
    this.assetStartIndex,
    required this.itemCount,
  });
}
