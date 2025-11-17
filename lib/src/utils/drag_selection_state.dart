import 'dart:async';
import 'package:flutter/material.dart';
import 'package:yuni_widget/yuni_widget.dart';
import '../config/album_settings.dart';

/// 拖拽选择状态管理类
/// 封装所有拖拽选择相关的状态和逻辑
class DragSelectionState {
  bool _isDragSelecting = false;
  Offset? _dragStartPosition;
  int? _lastDragIndex;
  Offset? _currentDragPosition;
  bool _isVerticalDrag = false;
  bool _dragDirectionDetermined = false;

  // 滚动位置保持
  double? _savedScrollOffset;

  // 拖拽选择模式：true为选中模式，false为取消选中模式
  bool _isSelectingMode = true;

  // 自动滚动相关
  Timer? _autoScrollTimer;
  
  Offset? _lastDragPosition; // 上次拖拽位置，用于检测位置变化

  /// 自动滚动边缘触发阈值（像素）
  /// 当拖拽位置距离视口边缘小于此值时，开始触发自动滚动
  /// 值越大，越容易触发自动滚动
  static const double _autoScrollEdgeThreshold = 120.0;

  /// 自动滚动外部阈值（像素）
  /// 当拖拽位置距离视口边缘小于此值时，使用最大滚动速度
  /// 此值应小于边缘阈值，用于创建速度渐变区域
  static const double _autoScrollOuterThreshold = 60.0;

  /// 基础滚动速度（像素/帧）
  /// 在16ms定时器下，每次滚动的基础像素数，使用较小的值确保平滑
  static const double _autoScrollSpeed = 2.5;

  /// 最大滚动速度倍数
  /// 当拖拽位置在外部阈值内时，滚动速度将乘以此倍数
  static const double _maxScrollSpeedMultiplier = 8.0;

  // Getters
  bool get isDragSelecting => _isDragSelecting;

  Offset? get dragStartPosition => _dragStartPosition;

  int? get lastDragIndex => _lastDragIndex;

  Offset? get currentDragPosition => _currentDragPosition;

  bool get isVerticalDrag => _isVerticalDrag;

  bool get dragDirectionDetermined => _dragDirectionDetermined;

  bool get isSelectingMode => _isSelectingMode;

  double? get savedScrollOffset => _savedScrollOffset;

  // Setters
  set isDragSelecting(bool value) => _isDragSelecting = value;

  set dragStartPosition(Offset? value) => _dragStartPosition = value;

  set lastDragIndex(int? value) => _lastDragIndex = value;

  set currentDragPosition(Offset? value) => _currentDragPosition = value;

  set isVerticalDrag(bool value) => _isVerticalDrag = value;

  set dragDirectionDetermined(bool value) => _dragDirectionDetermined = value;

  set isSelectingMode(bool value) => _isSelectingMode = value;

  set savedScrollOffset(double? value) => _savedScrollOffset = value;

  /// 重置拖拽状态
  void resetDragState() {
    _isDragSelecting = false;
    _dragStartPosition = null;
    _lastDragIndex = null;
    _currentDragPosition = null;
    _isVerticalDrag = false;
    _dragDirectionDetermined = false;
    _stopAutoScroll();
  }

  /// 更新拖拽位置（用于动态调整滚动速度）
  void updateDragPosition(Offset position) {
    _lastDragPosition = position;
  }

  /// 停止自动滚动
  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    _lastDragPosition = null;
  }

  /// 开始自动滚动
  void startAutoScroll(
    ScrollController scrollController,
    Offset position,
    BuildContext context,
  ) {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final viewportHeight = renderBox.size.height;
    final targetScrollSpeedMultiplier = _calculateScrollSpeed(
      position,
      viewportHeight,
    );

    // 如果不在滚动区域内，停止滚动
    if (targetScrollSpeedMultiplier == 0.0) {
      _stopAutoScroll();
      return;
    }

    // 更新拖拽位置
    _lastDragPosition = position;

    // 如果定时器已经在运行，不需要重新创建
    if (_autoScrollTimer != null && _autoScrollTimer!.isActive) {
      return;
    }

    // 使用更平滑的定时器频率
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (
      timer,
    ) {
      if (!scrollController.hasClients) {
        _stopAutoScroll();
        return;
      }

      // 重新计算当前位置的目标速度（因为拖拽位置可能已经改变）
      final currentPosition = _lastDragPosition ?? position;
      final currentTargetSpeedMultiplier = _calculateScrollSpeed(
        currentPosition,
        viewportHeight,
      );

      // 如果不在滚动区域内，停止滚动
      if (currentTargetSpeedMultiplier == 0.0) {
        _stopAutoScroll();
        return;
      }

      final currentOffset = scrollController.offset;
      final maxScrollExtent = scrollController.position.maxScrollExtent;

      // 使用更小的滚动步长，提供更平滑的滚动
      final scrollDistance = currentTargetSpeedMultiplier * _autoScrollSpeed;
      final newOffset = (currentOffset + scrollDistance).clamp(
        0.0,
        maxScrollExtent,
      );

      if (newOffset != currentOffset) {
        // 使用jumpTo实现即时滚动，避免动画延迟
        scrollController.jumpTo(newOffset);
      } else {
        // 已经到达边界，停止滚动
        _stopAutoScroll();
      }
    });
  }

  /// 计算滚动速度倍数
  double _calculateScrollSpeed(Offset position, double viewportHeight) {
    // 上边界区域
    if (position.dy < _autoScrollEdgeThreshold) {
      // 在边界阈值内，计算距离边界的比例
      double distanceFromEdge = _autoScrollEdgeThreshold - position.dy;
      double normalizedDistance = (distanceFromEdge / _autoScrollEdgeThreshold)
          .clamp(0.0, 1.0);

      // 在外部阈值内时，使用最大速度倍数
      if (position.dy < _autoScrollOuterThreshold) {
        return -_maxScrollSpeedMultiplier;
      }

      // 在边界阈值和外部阈值之间，线性插值速度
      return -(1.0 + (normalizedDistance * (_maxScrollSpeedMultiplier - 1.0)));
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

  /// 保存当前滚动位置
  void saveScrollPosition(ScrollController scrollController) {
    if (scrollController.hasClients) {
      _savedScrollOffset = scrollController.offset;
    }
  }

  /// 恢复滚动位置
  void restoreScrollPosition(ScrollController scrollController) {
    if (_savedScrollOffset != null && scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients && _savedScrollOffset != null) {
          scrollController.jumpTo(_savedScrollOffset!);
        }
      });
    }
  }

  /// 清理资源
  void dispose() {
    _stopAutoScroll();
  }

  /// 根据布局格式计算item宽度
  ///
  /// [layoutFormat] 布局格式
  /// [screenWidth] 屏幕宽度
  /// [crossAxisCount] 列数
  /// [crossAxisSpacing] 横向间距
  /// [padding] 内边距
  static double calculateItemWidth({
    required AlbumLayoutFormat layoutFormat,
    required double screenWidth,
    int crossAxisCount = 3,
    double crossAxisSpacing = 1.5,
    EdgeInsets? padding,
  }) {
    final paddingHorizontal = padding?.horizontal ?? 0.0;
    final availableWidth = screenWidth - paddingHorizontal;

    switch (layoutFormat) {
      case AlbumLayoutFormat.gridView:
      case AlbumLayoutFormat.fileView:
        // 网格视图和文件视图：根据列数计算宽度
        return (availableWidth - (crossAxisSpacing * (crossAxisCount - 1))) /
            crossAxisCount;
      case AlbumLayoutFormat.listView:
        // 列表视图：占满宽度
        return availableWidth;
    }
  }

  /// 计算不同布局格式下的 item 高度
  ///
  /// [layoutFormat] 布局格式
  /// [screenWidth] 屏幕宽度
  /// [crossAxisCount] 列数（仅对 gridView 和 fileView 有效）
  /// [crossAxisSpacing] 列间距
  /// [mainAxisSpacing] 行间距
  /// [padding] 内边距
  /// [isDesktop] 是否为桌面端
  static double calculateItemHeight({
    required AlbumLayoutFormat layoutFormat,
    required double screenWidth,
    int crossAxisCount = 3,
    double crossAxisSpacing = 1.5,
    double mainAxisSpacing = 1.5,
    EdgeInsets? padding,
  }) {
    final paddingHorizontal = padding?.horizontal ?? 0.0;
    final availableWidth = screenWidth - paddingHorizontal;

    switch (layoutFormat) {
      case AlbumLayoutFormat.gridView:
        // 移动端：正方形网格，childAspectRatio = 1.0
        final itemWidth =
            (availableWidth - (crossAxisSpacing * (crossAxisCount - 1))) /
            crossAxisCount;
        return itemWidth; // 正方形，宽高相等

      case AlbumLayoutFormat.listView:
        // 移动端列表视图：固定高度的列表项
        return 60.0; // 根据实际的列表项高度调整

      case AlbumLayoutFormat.fileView:
        // 移动端文件视图：childAspectRatio = 3/4
        final itemWidth =
            (availableWidth - (crossAxisSpacing * (crossAxisCount - 1))) /
            crossAxisCount;
        return itemWidth * (4.0 / 3.0); // 宽高比 3:4
    }
  }

  /// 根据布局格式获取列数
  ///
  /// [layoutFormat] 布局格式
  /// [isDesktop] 是否为桌面端
  static int getCrossAxisCount({required AlbumLayoutFormat layoutFormat}) {
    switch (layoutFormat) {
      case AlbumLayoutFormat.gridView:
        return 3;
      case AlbumLayoutFormat.listView:
        return 1; // 列表视图只有一列
      case AlbumLayoutFormat.fileView:
        return 3; // 文件视图固定3列
    }
  }

  /// 根据布局格式获取间距
  ///
  /// [layoutFormat] 布局格式
  /// [isDesktop] 是否为桌面端
  static ({double crossAxisSpacing, double mainAxisSpacing}) getSpacing({
    required AlbumLayoutFormat layoutFormat,
  }) {
    switch (layoutFormat) {
      case AlbumLayoutFormat.gridView:
        return (crossAxisSpacing: 1.5, mainAxisSpacing: 1.5);
      case AlbumLayoutFormat.listView:
        return (crossAxisSpacing: 0.0, mainAxisSpacing: 0.0);
      case AlbumLayoutFormat.fileView:
        final config = YuniWidgetConfig.instance;
        return (
          crossAxisSpacing: config.spacing.sm,
          mainAxisSpacing: config.spacing.sm,
        );
    }
  }
}

