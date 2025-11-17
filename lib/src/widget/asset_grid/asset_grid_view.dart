import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:yuni_widget/yuni_widget.dart';
import '../../model/photo_picker_state.dart';
import '../../widget/photo_picker_item.dart';
import '../../config/photo_picker_config.dart';
import 'asset_drag_region.dart';
import 'asset_grid_data_structure.dart';
import '../../service/photo_picker_service.dart';
import '../../constants/constants.dart';

/// 网格选择状态监听
/// - active: 当前是否存在选中
/// - ids: 已选中的资产ID集合
typedef AssetGridSelectionListener = void Function(bool, Set<String>);

/// 资产网格视图
/// - 支持月/日标题的分组渲染
/// - 支持长按拖拽范围选择（含边缘自动滚动）
class AssetGridView extends StatefulWidget {
  final RenderList renderList;
  final int assetsPerRow;
  final double margin;
  final bool selectionActive;
  final Future<void> Function()? onRefresh;
  final AssetGridSelectionListener? listener;
  final bool shrinkWrap;
  final bool showDragScroll;
  final bool showStack;
  final bool showLabel;
  final ScrollController? controller;
  final PhotoPickerConfig config;
  final void Function(int index)? onItemTap;
  final void Function(int index)? onItemLongPress;

  const AssetGridView({
    super.key,
    required this.renderList,
    required this.assetsPerRow,
    this.margin = 2.0,
    this.selectionActive = false,
    this.onRefresh,
    this.listener,
    this.shrinkWrap = false,
    this.showDragScroll = true,
    this.showStack = false,
    this.showLabel = true,
    this.controller,
    required this.config,
    this.onItemTap,
    this.onItemLongPress,
  });

  @override
  State<AssetGridView> createState() => _AssetGridViewState();
}

/// 网格视图状态
class _AssetGridViewState extends State<AssetGridView> {
  final Set<String> _selectedIds = <String>{};
  bool _dragging = false;
  int? _dragAnchorAssetIndex;
  int? _dragAnchorSectionIndex;
  final Set<String> _draggedIds = <String>{};
  Set<String>? _originalSelectedIdsBeforeDrag;
  bool _dragTargetSelect = true;

  @override
  void initState() {
    super.initState();
    for (final a in widget.renderList.allAssets) {
      if (a.isSelected) _selectedIds.add(a.asset.id);
    }
  }

  @override
  void didUpdateWidget(covariant AssetGridView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.renderList, oldWidget.renderList)) {
      _selectedIds.clear();
      for (final a in widget.renderList.allAssets) {
        if (a.isSelected) _selectedIds.add(a.asset.id);
      }
    }
  }

  void _callListener(bool active) =>
      widget.listener?.call(active, Set.of(_selectedIds));

  /// 选中一组资产（支持拖拽增量记录）
  void _selectAssets(List<ChoiceAssetEntity> assets) {
    setState(() {
      if (_dragging) {
        _draggedIds.addAll(assets.map((e) => e.asset.id));
      }
      _selectedIds.addAll(assets.map((e) => e.asset.id));
      _callListener(true);
    });
  }

  /// 取消选中一组资产（支持拖拽增量记录）
  void _deselectAssets(List<ChoiceAssetEntity> assets) {
    setState(() {
      final ids = assets.map((e) => e.asset.id);
      _selectedIds.removeAll(ids);
      if (_dragging) {
        _draggedIds.removeAll(ids);
      }
      _callListener(_selectedIds.isNotEmpty);
    });
  }

  // /// 清空所有选中
  // void _deselectAll() {
  //   setState(() {
  //     _selectedIds.clear();
  //     _dragAnchorAssetIndex = null;
  //     _dragAnchorSectionIndex = null;
  //     _draggedIds.clear();
  //     _dragging = false;
  //     _callListener(false);
  //   });
  // }
  //
  // /// 检查当前分片是否全部选中（仅在多选活跃时生效）
  // bool _allSelected(List<ChoiceAssetEntity> assets) =>
  //     widget.selectionActive && assets.where((e) => !_selectedIds.contains(e.asset.id)).isEmpty;

  /// 设置拖拽锚点，并根据锚点初始选中状态确定拖拽方向
  /// - 未选中锚点：进入“选中范围”模式
  /// - 已选中锚点：进入“取消选中范围”模式
  void _setDragStartIndex(AssetIndex index) {
    final section = widget.renderList.elements[index.sectionIndex];
    final absoluteIndex = section.offset + index.rowIndex;
    final asset = widget.renderList.loadAsset(absoluteIndex);
    final isSelected = _selectedIds.contains(asset.asset.id);
    // 预加载后续缩略图，降低自动下滑过程中首次解码卡顿
    try {
      final all = widget.renderList.allAssets;
      if (all.isNotEmpty) {
        final start = (absoluteIndex + widget.assetsPerRow).clamp(0, all.length);
        final end = (start + widget.assetsPerRow * 40).clamp(0, all.length); // 预取约40行
        final upcoming = all.sublist(start, end).map((e) => e.asset).toList();
        PhotoPickerService.preloadThumbnails(upcoming, defaultAssetGridPreviewSize);
      }
    } catch (_) {}
    setState(() {
      _originalSelectedIdsBeforeDrag = Set.of(_selectedIds);
      _dragTargetSelect = !isSelected;
      _dragAnchorAssetIndex = index.rowIndex;
      _dragAnchorSectionIndex = index.sectionIndex;
      _dragging = true;
      if (_dragTargetSelect) {
        if (!_originalSelectedIdsBeforeDrag!.contains(asset.asset.id)) {
          _selectAssets([asset]);
          _draggedIds.add(asset.asset.id);
        }
      } else {
        if (_originalSelectedIdsBeforeDrag!.contains(asset.asset.id)) {
          _deselectAssets([asset]);
          _draggedIds.add(asset.asset.id);
        }
      }
    });
  }

  /// 结束拖拽选择，清理临时状态
  void _stopDrag() {
    setState(() {
      _dragging = false;
      _draggedIds.clear();
      _originalSelectedIdsBeforeDrag = null;
    });
  }

  /// 处理拖拽进入新资产索引：
  /// 1) 计算锚点与当前索引的范围
  /// 2) 回滚上一次范围的临时改动
  /// 3) 按拖拽目标方向对新范围执行“选中”或“取消选中”
  void _handleDragAssetEnter(AssetIndex index) {
    if (_dragAnchorSectionIndex == null || _dragAnchorAssetIndex == null) {
      return;
    }
    final dragAnchorSectionIndex = _dragAnchorSectionIndex!;
    final dragAnchorAssetIndex = _dragAnchorAssetIndex!;

    late final int startSectionIndex;
    late final int startSectionAssetIndex;
    late final int endSectionIndex;
    late final int endSectionAssetIndex;

    if (index.sectionIndex < dragAnchorSectionIndex) {
      startSectionIndex = index.sectionIndex;
      startSectionAssetIndex = index.rowIndex;
      endSectionIndex = dragAnchorSectionIndex;
      endSectionAssetIndex = dragAnchorAssetIndex;
    } else if (index.sectionIndex > dragAnchorSectionIndex) {
      startSectionIndex = dragAnchorSectionIndex;
      startSectionAssetIndex = dragAnchorAssetIndex;
      endSectionIndex = index.sectionIndex;
      endSectionAssetIndex = index.rowIndex;
    } else {
      startSectionIndex = dragAnchorSectionIndex;
      endSectionIndex = dragAnchorSectionIndex;
      if (dragAnchorAssetIndex < index.rowIndex) {
        startSectionAssetIndex = dragAnchorAssetIndex;
        endSectionAssetIndex = index.rowIndex;
      } else {
        startSectionAssetIndex = index.rowIndex;
        endSectionAssetIndex = dragAnchorAssetIndex;
      }
    }

    // 计算范围内的资产集合
    final selected = <ChoiceAssetEntity>[];
    var currentSectionIndex = startSectionIndex;
    while (currentSectionIndex < endSectionIndex) {
      final section = widget.renderList.elements[currentSectionIndex];
      final sectionAssets = widget.renderList.loadAssets(
        section.offset,
        section.count,
      );
      if (currentSectionIndex == startSectionIndex) {
        selected.addAll(sectionAssets.sublist(startSectionAssetIndex));
      } else {
        selected.addAll(sectionAssets);
      }
      currentSectionIndex += 1;
    }

    final endSection = widget.renderList.elements[endSectionIndex];
    final endAssets = widget.renderList.loadAssets(
      endSection.offset,
      endSection.count,
    );
    if (startSectionIndex == endSectionIndex) {
      selected.addAll(
        endAssets.sublist(startSectionAssetIndex, endSectionAssetIndex + 1),
      );
    } else {
      selected.addAll(endAssets.sublist(0, endSectionAssetIndex + 1));
    }

    // 回滚上一范围的临时改动，保证仅对“最新范围”生效
    if (_originalSelectedIdsBeforeDrag != null && _draggedIds.isNotEmpty) {
      final reverted =
          widget.renderList.allAssets
              .where((e) => _draggedIds.contains(e.asset.id))
              .toList();
      if (_dragTargetSelect) {
        _deselectAssets(reverted);
      } else {
        final needReselect =
            reverted
                .where(
                  (e) => _originalSelectedIdsBeforeDrag!.contains(e.asset.id),
                )
                .toList();
        if (needReselect.isNotEmpty) {
          _selectAssets(needReselect);
        }
      }
      _draggedIds.clear();
    }

    // 对最新范围执行目标方向的选择/取消
    if (_dragTargetSelect) {
      final toApply =
          selected
              .where(
                (e) => !_originalSelectedIdsBeforeDrag!.contains(e.asset.id),
              )
              .toList();
      if (toApply.isNotEmpty) {
        _selectAssets(toApply);
        _draggedIds.addAll(toApply.map((e) => e.asset.id));
      }
    } else {
      final toApply =
          selected
              .where(
                (e) => _originalSelectedIdsBeforeDrag!.contains(e.asset.id),
              )
              .toList();
      if (toApply.isNotEmpty) {
        _deselectAssets(toApply);
        _draggedIds.addAll(toApply.map((e) => e.asset.id));
      }
    }
  }

  /// 构建单个分组段：
  /// - 月份大标题（monthTitle）
  /// - 每日小标题（groupDividerTitle）
  /// - 资源网格行
  Widget _buildSection(RenderAssetGridElement section, int sectionIndex) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth / widget.assetsPerRow -
            widget.margin * (widget.assetsPerRow - 1) / widget.assetsPerRow;
        final rows =
            (section.count + widget.assetsPerRow - 1) ~/ widget.assetsPerRow;
        final assetsToRender = widget.renderList.loadAssets(
          section.offset,
          section.count,
        );
        final config = YuniWidgetConfig.instance;
        return Column(
          key: ValueKey(section.offset),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (section.type == RenderAssetGridElementType.monthTitle)
              Padding(
                key: Key('month-${section.title ?? ''}'),
                padding: EdgeInsets.symmetric(vertical: config.spacing.sm),
                child: YText(
                  '${section.date.year}年${section.date.month}月',
                  style: config.textStyles.bodyLargeBold,
                ),
              ),
            if (section.type == RenderAssetGridElementType.groupDividerTitle)
              Padding(
                padding: EdgeInsets.symmetric(vertical: config.spacing.sm),
                child: YText(
                  section.title ?? '',
                  style: config.textStyles.bodyMediumBold,
                ),
              ),
            for (int i = 0; i < rows; i++)
              _AssetRow(
                key: ValueKey(i),
                rowStartIndex: i * widget.assetsPerRow,
                sectionIndex: sectionIndex,
                assets: assetsToRender.sublist(
                  i * widget.assetsPerRow,
                  min((i + 1) * widget.assetsPerRow, section.count),
                ),
                absoluteOffset: section.offset + i * widget.assetsPerRow,
                width: width,
                assetsPerRow: widget.assetsPerRow,
                margin: widget.margin,
                isSelectionActive: widget.selectionActive,
                selectedIds: _selectedIds,
                onSelect: (asset) => _selectAssets([asset]),
                onDeselect: (asset) => _deselectAssets([asset]),
                onItemTap: (localIndex) {
                  final global = section.offset + localIndex;
                  widget.onItemTap?.call(global);
                },
                onItemLongPress: (localIndex) {
                  final global = section.offset + localIndex;
                  widget.onItemLongPress?.call(global);
                },
                config: widget.config,
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final listWidget = ListView.builder(
      shrinkWrap: widget.shrinkWrap,
      controller: widget.controller,
      itemCount: widget.renderList.elements.length,
      itemBuilder:
          (c, index) => _buildSection(widget.renderList.elements[index], index),
    );

    final child =
        widget.onRefresh == null
            ? listWidget
            : RefreshIndicator(onRefresh: widget.onRefresh!, child: listWidget);

    // 包裹 AssetDragRegion 以接管长按拖拽并实现边缘自动滚动
    return Stack(
      children: [
        AssetDragRegion(
          onStart: _setDragStartIndex,
          onAssetEnter: _handleDragAssetEnter,
          onEnd: _stopDrag,
          onScrollStart: () {},
          onScroll: (direction, speed) {
            final controller = widget.controller;
            if (controller == null || !controller.hasClients) return;
            final position = controller.position;
            final base = 3.0;
            final delta = (base + 12.0 * speed);
            switch (direction) {
              case ScrollDirection.forward:
                controller.jumpTo(
                  (controller.offset + delta).clamp(
                    0.0,
                    position.maxScrollExtent,
                  ),
                );
                break;
              case ScrollDirection.reverse:
                controller.jumpTo(
                  (controller.offset - delta).clamp(
                    0.0,
                    position.maxScrollExtent,
                  ),
                );
                break;
              case ScrollDirection.idle:
                break;
            }
          },
          child: child,
        ),
      ],
    );
  }
}

class _AssetRow extends StatelessWidget {
  final List<ChoiceAssetEntity> assets;
  final int rowStartIndex;
  final int sectionIndex;
  final Set<String> selectedIds;
  final int absoluteOffset;
  final double width;
  final double margin;
  final int assetsPerRow;
  final bool isSelectionActive;
  final void Function(ChoiceAssetEntity) onSelect;
  final void Function(ChoiceAssetEntity) onDeselect;
  final void Function(int index)? onItemTap;
  final void Function(int index)? onItemLongPress;
  final PhotoPickerConfig config;

  const _AssetRow({
    super.key,
    required this.rowStartIndex,
    required this.sectionIndex,
    required this.assets,
    required this.absoluteOffset,
    required this.width,
    required this.margin,
    required this.assetsPerRow,
    required this.isSelectionActive,
    required this.selectedIds,
    required this.onSelect,
    required this.onDeselect,
    this.onItemTap,
    this.onItemLongPress,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(assets.length, (index) {
        final asset = assets[index];
        final last = index + 1 == assetsPerRow;
        final isSelected =
            isSelectionActive && selectedIds.contains(asset.asset.id);
        return Container(
          width: width,
          height: width,
          margin: EdgeInsets.only(bottom: margin, right: last ? 0.0 : margin),
          child: GestureDetector(
            onTap: () {
              if (isSelectionActive) {
                if (isSelected) {
                  onDeselect(asset);
                } else {
                  onSelect(asset);
                }
              } else {
                HapticFeedback.selectionClick();
                onItemTap?.call(index);
              }
            },
            onLongPress: () {
              HapticFeedback.heavyImpact();
            },
            child: AssetIndexWrapper(
              rowIndex: rowStartIndex + index,
              sectionIndex: sectionIndex,
              child: PhotoPickerItem(entity: asset, config: config),
            ),
          ),
        );
      }),
    );
  }
}
