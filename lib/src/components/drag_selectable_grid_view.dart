import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:yuni_widget/yuni_widget.dart';
import 'dart:async';
import 'dart:math' as math;
import '../config/album_settings.dart';
import '../utils/drag_selection_state.dart';

/// 支持滑动选择的GridView组件
/// 可以通过滑动手势快速选中或取消选中多个item
class DragSelectableGridView extends StatefulWidget {
  /// GridView的子组件构建器
  final Widget Function(BuildContext context, int index) itemBuilder;

  /// item总数
  final int itemCount;

  /// 网格列数
  final int crossAxisCount;

  /// 列间距
  final double crossAxisSpacing;

  /// 行间距
  final double mainAxisSpacing;

  /// GridView的padding
  final EdgeInsetsGeometry? padding;

  /// 滚动控制器
  final ScrollController? controller;

  /// 是否启用滑动选择功能
  final bool enableDragSelection;

  /// 选择控制器（可选，如果不提供会自动创建）
  final DragSelectionController? selectionController;

  /// 选择模式
  final SelectionMode selectionMode;

  /// 最大选择数量限制
  final int maxSelection;

  /// 滑动选择开始回调，返回起始索引
  final void Function(int index)? onDragSelectionStart;

  /// 滑动选择更新回调，返回当前索引
  final void Function(int index)? onDragSelectionUpdate;

  /// 滑动选择结束回调
  final void Function()? onDragSelectionEnd;

  /// 选中状态变化回调
  final void Function(Set<int> selectedIndices)? onSelectionChanged;

  /// 单个项目选择状态变化回调
  final void Function(int index, bool isSelected)? onItemSelectionChanged;

  /// 获取指定索引item的选中状态（如果提供了selectionController则忽略此回调）
  final bool Function(int index)? isItemSelected;

  /// 点击item回调
  final void Function(int index)? onItemTap;

  /// 长按item回调（可用于启动滑动选择）
  final void Function(int index)? onItemLongPress;

  /// 布局格式
  final AlbumLayoutFormat layoutFormat;

  /// GridView的其他属性
  final Axis scrollDirection;
  final bool reverse;
  final bool? primary;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final double? cacheExtent;
  final int? semanticChildCount;
  final DragStartBehavior dragStartBehavior;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;
  final String? restorationId;
  final Clip clipBehavior;

  const DragSelectableGridView({
    super.key,
    required this.itemBuilder,
    required this.itemCount,
    required this.crossAxisCount,
    this.crossAxisSpacing = 0.0,
    this.mainAxisSpacing = 0.0,
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
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.cacheExtent,
    this.semanticChildCount,
    this.dragStartBehavior = DragStartBehavior.start,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
  });

  @override
  State<DragSelectableGridView> createState() => _DragSelectableGridViewState();
}

class _DragSelectableGridViewState extends State<DragSelectableGridView> {
  late final DragSelectionController _selectionController;
  bool _isInternalController = false;

  // 拖拽状态
  bool _isDragSelecting = false;
  int _lastDragIndex = -1;
  Offset? _currentDragPosition;
  Offset? _dragStartPosition;
  bool _isVerticalDrag = false;
  bool _dragDirectionDetermined = false;

  // 自动滚动相关
  Timer? _autoScrollTimer;
  static const double _autoScrollEdgeThreshold = 100.0; // 边界阈值
  static const double _autoScrollOuterThreshold = 50.0; // 外部阈值
  static const double _autoScrollSpeed = 8.0; // 基础滚动速度
  static const double _maxScrollSpeedMultiplier = 8.0; // 最大速度倍数
  int _lastProcessedRow = -1;

  @override
  void initState() {
    super.initState();
    _initializeSelectionController();
  }

  void _initializeSelectionController() {
    if (widget.selectionController != null) {
      _selectionController = widget.selectionController!;
      _isInternalController = false;
    } else {
      _selectionController = DragSelectionController(
        selectionMode: widget.selectionMode,
        maxSelection: widget.maxSelection,
        onSelectionChanged: widget.onSelectionChanged,
        onItemSelectionChanged: widget.onItemSelectionChanged,
      );
      _isInternalController = true;
    }
  }

  @override
  void didUpdateWidget(DragSelectableGridView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 如果选择控制器发生变化，需要重新初始化
    if (widget.selectionController != oldWidget.selectionController) {
      if (_isInternalController) {
        _selectionController.dispose();
      }
      _initializeSelectionController();
    }
  }

  @override
  void dispose() {
    _stopAutoScroll();
    if (_isInternalController) {
      _selectionController.dispose();
    }
    super.dispose();
  }

  void _handleItemTap(int index) {
    widget.onItemTap?.call(index);

    // 如果使用内部控制器，处理选择逻辑
    if (widget.selectionController != null || _isInternalController) {
      _selectionController.toggleSelection(index);
    }
  }

  /// 处理item长按
  void _handleItemLongPress(int index) {
    widget.onItemLongPress?.call(index);

    // 如果启用滑动选择且使用内部控制器，开始滑动选择
    if (widget.enableDragSelection &&
        (widget.selectionController != null || _isInternalController)) {
      _selectionController.startDragSelection(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gridView = GridView.builder(
      controller: widget.controller,
      padding: widget.padding,
      scrollDirection: widget.scrollDirection,
      reverse: widget.reverse,
      primary: widget.primary,
      physics: widget.physics,
      shrinkWrap: widget.shrinkWrap,
      cacheExtent: widget.cacheExtent,
      semanticChildCount: widget.semanticChildCount,
      dragStartBehavior: widget.dragStartBehavior,
      keyboardDismissBehavior: widget.keyboardDismissBehavior,
      restorationId: widget.restorationId,
      clipBehavior: widget.clipBehavior,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        crossAxisSpacing: widget.crossAxisSpacing,
        mainAxisSpacing: widget.mainAxisSpacing,
      ),
      itemCount: widget.itemCount,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _handleItemTap(index),
          onLongPress: () => _handleItemLongPress(index),
          child: widget.itemBuilder(context, index),
        );
      },
    );

    if (!widget.enableDragSelection) {
      return gridView;
    }

    return GestureDetector(
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      child: gridView,
    );
  }

  void _handlePanStart(DragStartDetails details) {
    final index = _getIndexFromPosition(details.localPosition);
    if (index != null && index >= 0 && index < widget.itemCount) {
      _isDragSelecting = true;
      _lastDragIndex = index;
      _currentDragPosition = details.localPosition;
      _dragStartPosition = details.localPosition; // 记录拖拽起始位置
      _isVerticalDrag = false; // 重置垂直拖拽标记
      _dragDirectionDetermined = false; // 重置方向确定标记

      // 使用选择控制器开始滑动选择
      if (widget.selectionController != null || _isInternalController) {
        _selectionController.startDragSelection(index);
      }

      widget.onDragSelectionStart?.call(index);
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!_isDragSelecting) return;

    _currentDragPosition = details.localPosition;

    // 恢复自动滚动检查：不论方向，靠近边缘时触发滚动
    _checkAndStartAutoScroll(details.localPosition);

    // 如果方向还未确定，先判断拖拽方向
    if (!_dragDirectionDetermined && _dragStartPosition != null) {
      final dx = (details.localPosition.dx - _dragStartPosition!.dx).abs();
      final dy = (details.localPosition.dy - _dragStartPosition!.dy).abs();

      // 当拖拽距离超过阈值时确定方向
      if (dx > 10 || dy > 10) {
        _isVerticalDrag = dy > dx; // 垂直移动距离大于水平移动距离则为垂直拖拽
        _dragDirectionDetermined = true; // 方向确定
      }
    }

    // 不再因自动滚动而阻断选择；根据拖拽方向执行对应选择逻辑
    if (_isVerticalDrag) {
      // 垂直拖拽：选中整行
      _handleVerticalDragSelection(details.localPosition);
    } else {
      // 水平拖拽：连续选择
      final index = _getIndexFromPosition(details.localPosition);
      if (index != null &&
          index >= 0 &&
          index < widget.itemCount &&
          index != _lastDragIndex) {
        _selectContinuousRange(_lastDragIndex, index);
        _lastDragIndex = index;
      }
    }
  }

  /// 处理垂直拖拽时的整行选中
  void _handleVerticalDragSelection(Offset position) {
    final index = _getIndexFromPosition(position);
    if (index == null || index < 0 || index >= widget.itemCount) return;

    // 计算当前item所在的行
    final currentRow = index ~/ widget.crossAxisCount;

    // 如果是新的一行，使用连续行选择
    if (currentRow != _lastProcessedRow) {
      // 使用连续行选择，确保选中从上一行到当前行之间的所有行
      _selectContinuousRows(_lastProcessedRow, currentRow);
      _lastProcessedRow = currentRow;

      // 更新_lastDragIndex为当前行的最后一个item
      _lastDragIndex = (currentRow * widget.crossAxisCount +
              widget.crossAxisCount -
              1)
          .clamp(0, widget.itemCount - 1);
    }
  }

  /// 处理连续选择：选中从startIndex到endIndex之间的所有项目
  void _selectContinuousRange(int startIndex, int endIndex) {
    if (startIndex == endIndex) {
      // 如果起始和结束索引相同，只选中一个项目
      if (widget.selectionController != null || _isInternalController) {
        _selectionController.updateDragSelection(startIndex);
      }
      widget.onDragSelectionUpdate?.call(startIndex);
      return;
    }

    // 确保startIndex小于endIndex
    final minIndex = math.min(startIndex, endIndex);
    final maxIndex = math.max(startIndex, endIndex);

    // 选中范围内的所有项目
    for (int i = minIndex; i <= maxIndex; i++) {
      if (i >= 0 && i < widget.itemCount) {
        if (widget.selectionController != null || _isInternalController) {
          _selectionController.updateDragSelection(i);
        }
        widget.onDragSelectionUpdate?.call(i);
      }
    }
  }

  /// 处理连续行选择：选中从startRow到endRow之间的所有行
  void _selectContinuousRows(int startRow, int endRow) {
    // 处理初始行为负的情况（尚未处理过任何行时）
    if (startRow < 0) {
      _selectEntireRow(endRow);
      return;
    }

    if (startRow == endRow) {
      // 如果起始和结束行相同，只选中一行
      _selectEntireRow(startRow);
      return;
    }

    // 确保起始行不为负
    final minRow = math.max(0, math.min(startRow, endRow));
    final maxRow = math.max(startRow, endRow);

    // 选中范围内的所有行
    for (int row = minRow; row <= maxRow; row++) {
      _selectEntireRow(row);
    }
  }

  /// 选中整行
  void _selectEntireRow(int row) {
    for (int col = 0; col < widget.crossAxisCount; col++) {
      final itemIndex = row * widget.crossAxisCount + col;
      if (itemIndex >= 0 && itemIndex < widget.itemCount) {
        if (widget.selectionController != null || _isInternalController) {
          _selectionController.updateDragSelection(itemIndex);
        }
        widget.onDragSelectionUpdate?.call(itemIndex);
      }
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_isDragSelecting) {
      _isDragSelecting = false;
      _lastDragIndex = -1;
      _currentDragPosition = null;
      _dragStartPosition = null; // 重置拖拽起始位置
      _isVerticalDrag = false; // 重置垂直拖拽标记
      _dragDirectionDetermined = false; // 重置方向确定标记
      _lastProcessedRow = -1; // 重置处理的行索引
      _stopAutoScroll();
      widget.onDragSelectionEnd?.call();
    }
  }

  /// 检查并开始自动滚动
  void _checkAndStartAutoScroll(Offset position) {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final viewportHeight = renderBox.size.height;

    // 检查是否在滚动区域内
    bool shouldScroll = false;

    // 上边界检查
    if (position.dy < _autoScrollEdgeThreshold) {
      shouldScroll = true;
    }
    // 下边界检查
    else if (position.dy > viewportHeight - _autoScrollEdgeThreshold) {
      shouldScroll = true;
    }

    if (shouldScroll) {
      _startAutoScroll(position);
    } else {
      _stopAutoScroll();
    }
  }

  /// 开始自动滚动
  void _startAutoScroll(Offset position) {
    if (_autoScrollTimer?.isActive == true) return;

    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (
      timer,
    ) {
      if (!_isDragSelecting ||
          widget.controller == null ||
          !widget.controller!.hasClients) {
        _stopAutoScroll();
        return;
      }

      final scrollController = widget.controller!;
      final currentOffset = scrollController.offset;
      final maxScrollExtent = scrollController.position.maxScrollExtent;

      // 如果有当前拖拽位置，重新计算速度倍数以实现动态速度
      double currentSpeedMultiplier = 1.0;
      if (_currentDragPosition != null) {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          currentSpeedMultiplier = _calculateScrollSpeedMultiplier(
            _currentDragPosition!,
            renderBox.size.height,
          );
          // 如果速度倍数为0，停止滚动
          if (currentSpeedMultiplier == 0.0) {
            _stopAutoScroll();
            return;
          }
        }
      }

      // 计算当前帧的滚动速度
      double currentSpeed = _autoScrollSpeed * currentSpeedMultiplier;

      double newOffset;
      // 判断滚动方向：如果拖拽位置在视口上半部分则向上滚动
      if (_currentDragPosition != null) {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          bool scrollUp = _currentDragPosition!.dy < renderBox.size.height / 2;
          if (scrollUp) {
            newOffset = (currentOffset - currentSpeed).clamp(
              0.0,
              maxScrollExtent,
            );
          } else {
            newOffset = (currentOffset + currentSpeed).clamp(
              0.0,
              maxScrollExtent,
            );
          }
        } else {
          // 如果无法获取renderBox，使用阈值判断
          if (_currentDragPosition!.dy < _autoScrollEdgeThreshold) {
            newOffset = (currentOffset - currentSpeed).clamp(
              0.0,
              maxScrollExtent,
            );
          } else {
            newOffset = (currentOffset + currentSpeed).clamp(
              0.0,
              maxScrollExtent,
            );
          }
        }
      } else {
        // 如果没有当前拖拽位置，使用传入的position判断
        if (position.dy < _autoScrollEdgeThreshold) {
          newOffset = (currentOffset - currentSpeed).clamp(
            0.0,
            maxScrollExtent,
          );
        } else {
          newOffset = (currentOffset + currentSpeed).clamp(
            0.0,
            maxScrollExtent,
          );
        }
      }

      if (newOffset != currentOffset) {
        scrollController.jumpTo(newOffset);

        // 在自动滚动时处理整行选中逻辑
        _handleAutoScrollSelection();
      } else {
        // 已经到达边界，停止滚动
        _stopAutoScroll();
      }
    });
  }

  /// 处理自动滚动时的整行选中逻辑
  void _handleAutoScrollSelection() {
    // 仅在垂直拖拽时进行"整行"选中，避免水平拖拽被误选整行
    if (!_isVerticalDrag) return;

    if (_currentDragPosition == null) return;

    final index = _getIndexFromPosition(_currentDragPosition!);
    if (index == null || index < 0 || index >= widget.itemCount) return;

    // 计算当前item所在的行
    final currentRow = index ~/ widget.crossAxisCount;

    // 如果是新的一行，则选中整行
    if (currentRow != _lastProcessedRow) {
      _lastProcessedRow = currentRow;

      // 选中当前行的所有item
      for (int col = 0; col < widget.crossAxisCount; col++) {
        final rowItemIndex = currentRow * widget.crossAxisCount + col;
        if (rowItemIndex >= 0 && rowItemIndex < widget.itemCount) {
          _selectionController.updateDragSelection(rowItemIndex);
        }
      }
    }
  }

  /// 停止自动滚动
  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    _lastProcessedRow = -1;
  }

  /// 计算滚动速度倍数
  double _calculateScrollSpeedMultiplier(
    Offset position,
    double viewportHeight,
  ) {
    // 上边界区域
    if (position.dy < _autoScrollEdgeThreshold) {
      // 在边界阈值内，计算距离边界的比例
      double distanceFromEdge = _autoScrollEdgeThreshold - position.dy;
      double normalizedDistance = (distanceFromEdge / _autoScrollEdgeThreshold)
          .clamp(0.0, 1.0);

      // 在外部阈值内时，使用最大速度倍数
      if (position.dy < _autoScrollOuterThreshold) {
        return _maxScrollSpeedMultiplier;
      }

      // 在边界阈值和外部阈值之间，线性插值速度
      return 1.0 + (normalizedDistance * (_maxScrollSpeedMultiplier - 1.0));
    }

    // 下边界区域
    double bottomThreshold = viewportHeight - _autoScrollEdgeThreshold;
    if (position.dy > bottomThreshold) {
      // 在边界阈值内，计算距离边界的比例
      double distanceFromEdge = position.dy - bottomThreshold;
      double normalizedDistance = (distanceFromEdge / _autoScrollEdgeThreshold)
          .clamp(0.0, 1.0);

      // 在外部阈值内时，使用最大速度倍数
      double bottomOuterThreshold = viewportHeight - _autoScrollOuterThreshold;
      if (position.dy > bottomOuterThreshold) {
        return _maxScrollSpeedMultiplier;
      }

      // 在边界阈值和外部阈值之间，线性插值速度
      return 1.0 + (normalizedDistance * (_maxScrollSpeedMultiplier - 1.0));
    }

    // 不在滚动区域内
    return 0.0;
  }

  /// 根据滑动位置计算对应的item索引
  /// 优化版本：使用更精确的计算方法，避免在大滚动距离时的累积误差
  int? _getIndexFromPosition(Offset position) {
    try {
      // 获取屏幕宽度
      final screenWidth = MediaQuery.of(context).size.width;

      // 使用 DragSelectionState 的通用高度计算函数
      final spacing = DragSelectionState.getSpacing(
        layoutFormat: widget.layoutFormat,
      );

      final itemHeight = DragSelectionState.calculateItemHeight(
        layoutFormat: widget.layoutFormat,
        screenWidth: screenWidth,
        crossAxisCount: widget.crossAxisCount,
        crossAxisSpacing: spacing.crossAxisSpacing,
        mainAxisSpacing: spacing.mainAxisSpacing,
      );

      final itemWidth =
          widget.layoutFormat == AlbumLayoutFormat.listView
              ? screenWidth // 列表视图占满宽度
              : (screenWidth -
                      (spacing.crossAxisSpacing *
                          (widget.crossAxisCount - 1))) /
                  widget.crossAxisCount;

      // 获取当前滚动偏移量（使用更精确的方法）
      final scrollOffset =
          widget.controller?.hasClients == true
              ? widget.controller!.offset
              : 0.0;

      // 计算相对于GridView内容的实际位置
      final padding =
          widget.padding?.resolve(TextDirection.ltr) ?? EdgeInsets.zero;
      final paddingLeft = padding.left;
      final paddingTop = padding.top;

      // 计算相对于内容区域的X坐标
      final adjustedX = position.dx - paddingLeft;
      if (adjustedX < 0) return null;

      // 计算列索引（使用更精确的除法，避免精度问题）
      int col;
      if (widget.layoutFormat == AlbumLayoutFormat.listView) {
        col = 0; // 列表视图只有一列
      } else {
        // 使用更精确的计算方法：先计算总宽度，再计算列索引
        final totalItemWidth = itemWidth + spacing.crossAxisSpacing;
        col = (adjustedX / totalItemWidth).floor();
        // 确保列索引在有效范围内
        if (col < 0) return null;
        if (col >= widget.crossAxisCount) {
          // 如果超出范围，检查是否在最后一个item的范围内
          final lastColStartX = (widget.crossAxisCount - 1) * totalItemWidth;
          if (adjustedX < lastColStartX + itemWidth) {
            col = widget.crossAxisCount - 1;
          } else {
            return null;
          }
        }
      }

      // 计算相对于内容区域的Y坐标（考虑滚动偏移）
      // 使用更精确的计算：先计算总高度，再计算行索引
      final totalItemHeight = itemHeight + spacing.mainAxisSpacing;
      final adjustedY = position.dy - paddingTop + scrollOffset;

      if (adjustedY < 0) return null;

      // 计算行索引（使用更精确的除法）
      final row = (adjustedY / totalItemHeight).floor();
      if (row < 0) return null;

      // 计算最终索引
      final index = row * widget.crossAxisCount + col;

      // 边界检查
      if (index < 0 || index >= widget.itemCount) {
        // 如果索引超出范围，尝试使用更精确的方法计算
        // 检查是否在最后一个item的范围内
        final lastRow = (widget.itemCount - 1) ~/ widget.crossAxisCount;
        final lastCol = (widget.itemCount - 1) % widget.crossAxisCount;

        if (row == lastRow && col <= lastCol) {
          // 在最后一行，检查列是否在有效范围内
          if (col <= lastCol) {
            return row * widget.crossAxisCount + col;
          }
        }
        return null;
      }

      return index;
    } catch (e) {
      // 如果计算过程中出现异常，返回null
      debugPrint('Error calculating index from position: $e');
      return null;
    }
  }
}

/// 选择模式枚举
enum SelectionMode {
  /// 单选模式
  single,

  /// 多选模式
  multiple,
}

/// 滑动选择状态管理器
class DragSelectionController {
  bool _isDragSelecting = false;
  bool? _dragStartSelectState;
  int _lastDragIndex = -1;
  final Set<int> _selectedIndices = <int>{};

  /// 选择模式
  final SelectionMode selectionMode;

  /// 最大选择数量限制（仅在多选模式下有效）
  final int maxSelection;

  /// 选中状态变化回调
  final void Function(Set<int> selectedIndices)? onSelectionChanged;

  /// 单个项目选择状态变化回调（提供索引和选择状态）
  final void Function(int index, bool isSelected)? onItemSelectionChanged;

  DragSelectionController({
    this.selectionMode = SelectionMode.multiple,
    this.maxSelection = 999999,
    this.onSelectionChanged,
    this.onItemSelectionChanged,
  });

  /// 当前选中的索引集合
  Set<int> get selectedIndices => Set.unmodifiable(_selectedIndices);

  /// 是否正在滑动选择
  bool get isDragSelecting => _isDragSelecting;

  /// 检查指定索引是否被选中
  bool isSelected(int index) => _selectedIndices.contains(index);

  /// 检查指定索引是否被选中
  bool isSelectedChild(int index) => _selectedIndices.contains(index);

  /// 选中的数量
  int get selectedCount => _selectedIndices.length;

  /// 是否允许多选
  bool get allowMultiple => selectionMode == SelectionMode.multiple;

  /// 检查是否全选（需要传入总数量）
  bool isAllSelected(int totalCount) {
    if (totalCount == 0) return false;
    final maxSelectableCount =
        allowMultiple ? math.min(totalCount, maxSelection) : 1;
    return _selectedIndices.length == maxSelectableCount;
  }

  /// 开始滑动选择
  void startDragSelection(int index) {
    if (!allowMultiple) return; // 单选模式不支持滑动选择

    _isDragSelecting = true;
    _lastDragIndex = index;

    // 确定滑动的目标状态（与当前状态相反）
    _dragStartSelectState = !_selectedIndices.contains(index);

    // 立即处理起始位置
    _handleSelectionAtIndex(index);
  }

  /// 更新滑动选择
  void updateDragSelection(int index) {
    if (!_isDragSelecting || index == _lastDragIndex) return;

    _lastDragIndex = index;
    _handleSelectionAtIndex(index);
  }

  /// 结束滑动选择
  void endDragSelection() {
    _isDragSelecting = false;
    _dragStartSelectState = null;
    _lastDragIndex = -1;
  }

  /// 处理指定索引的选择逻辑
  void _handleSelectionAtIndex(int index) {
    if (_dragStartSelectState == null) return;

    final targetState = _dragStartSelectState!;
    final currentState = _selectedIndices.contains(index);

    // 如果当前状态已经是目标状态，则不需要改变
    if (currentState == targetState) return;

    if (targetState) {
      // 要选中
      if (allowMultiple) {
        if (_selectedIndices.length < maxSelection) {
          _selectedIndices.add(index);
          _notifySelectionChanged(index, true);
        }
      } else {
        // 单选模式：先清除所有选择，再选中当前项
        _selectedIndices.clear();
        _selectedIndices.add(index);
        _notifySelectionChanged(index, true);
      }
    } else {
      // 要取消选中
      _selectedIndices.remove(index);
      _notifySelectionChanged(index, false);
    }
  }

  /// 切换指定索引的选中状态（用于点击选择）
  /// [targetSelected] 显式指定目标选择状态，null 表示切换
  void toggleSelection(int index, {bool? targetSelected}) {
    final currentState = _selectedIndices.contains(index);
    bool shouldSelect;

    if (targetSelected != null) {
      shouldSelect = targetSelected;
    } else {
      shouldSelect = !currentState;
    }

    // 如果目标状态与当前状态相同，不需要改变
    if (shouldSelect == currentState) return;

    if (allowMultiple) {
      // 多选模式
      if (shouldSelect) {
        if (_selectedIndices.length < maxSelection) {
          _selectedIndices.add(index);
          _notifySelectionChanged(index, true);
        } else {
          YToastHelper.toast("最多只能选择$maxSelection");
          return;
        }
      } else {
        _selectedIndices.remove(index);
        _notifySelectionChanged(index, false);
      }
    } else {
      // 单选模式
      if (shouldSelect) {
        _selectedIndices.clear();
        _selectedIndices.add(index);
        _notifySelectionChanged(index, true);
      } else {
        _selectedIndices.remove(index);
        _notifySelectionChanged(index, false);
      }
    }
  }

  /// 全选
  void selectAll(int itemCount) {
    if (!allowMultiple) return; // 单选模式不支持全选

    final maxCount = math.min(itemCount, maxSelection);
    final oldSelection = Set<int>.from(_selectedIndices);

    _selectedIndices.clear();
    for (int i = 0; i < maxCount; i++) {
      _selectedIndices.add(i);
    }

    // 通知变化
    onSelectionChanged?.call(_selectedIndices);

    // 通知每个项目的状态变化
    for (int i = 0; i < itemCount; i++) {
      final wasSelected = oldSelection.contains(i);
      final isSelected = _selectedIndices.contains(i);
      if (wasSelected != isSelected) {
        onItemSelectionChanged?.call(i, isSelected);
      }
    }
  }

  /// 取消全选
  void clearSelection() {
    final oldSelection = Set<int>.from(_selectedIndices);
    _selectedIndices.clear();

    onSelectionChanged?.call(_selectedIndices);

    // 通知每个项目的状态变化
    for (final index in oldSelection) {
      onItemSelectionChanged?.call(index, false);
    }
  }

  /// 切换全选状态
  void toggleSelectAll(int itemCount) {
    if (isAllSelected(itemCount)) {
      clearSelection();
    } else {
      selectAll(itemCount);
    }
  }

  /// 设置选中状态
  void setSelection(Set<int> indices) {
    final oldSelection = Set<int>.from(_selectedIndices);
    _selectedIndices.clear();

    if (allowMultiple) {
      final maxCount = math.min(indices.length, maxSelection);
      _selectedIndices.addAll(indices.take(maxCount));
    } else {
      // 单选模式只取第一个
      if (indices.isNotEmpty) {
        _selectedIndices.add(indices.first);
      }
    }

    onSelectionChanged?.call(_selectedIndices);

    // 通知每个项目的状态变化
    final allAffectedIndices = {...oldSelection, ..._selectedIndices};
    for (final index in allAffectedIndices) {
      final wasSelected = oldSelection.contains(index);
      final isSelected = _selectedIndices.contains(index);
      if (wasSelected != isSelected) {
        onItemSelectionChanged?.call(index, isSelected);
      }
    }
  }

  /// 通知选择状态变化
  void _notifySelectionChanged(int index, bool isSelected) {
    onSelectionChanged?.call(_selectedIndices);
    onItemSelectionChanged?.call(index, isSelected);
  }

  /// 释放资源
  void dispose() {
    _selectedIndices.clear();
  }
}
