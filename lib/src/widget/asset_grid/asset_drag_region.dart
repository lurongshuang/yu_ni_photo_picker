import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// 长按拖拽选择区域：
/// - 捕获长按开始/移动/结束事件
/// - 命中检测定位当前指尖下的资产索引（AssetIndex）
/// - 在靠近顶部/底部边缘时触发自动滚动并持续更新选择

class AssetDragRegion extends StatefulWidget {
  final Widget child;
  final void Function(AssetIndex valueKey)? onStart;
  final void Function(AssetIndex valueKey)? onAssetEnter;
  final void Function()? onEnd;
  final void Function()? onScrollStart;
  final void Function(ScrollDirection direction, double speedMultiplier)? onScroll;

  const AssetDragRegion({
    super.key,
    required this.child,
    this.onStart,
    this.onAssetEnter,
    this.onEnd,
    this.onScrollStart,
    this.onScroll,
  });

  @override
  State createState() => _AssetDragRegionState();
}

class _AssetDragRegionState extends State<AssetDragRegion> {
  AssetIndex? assetUnderPointer;
  AssetIndex? anchorAsset;
  Offset? _lastGlobalPosition;

  static const double scrollOffset = 0.10; // 边缘自动滚动触发阈值（相对高度）
  double? topScrollOffset;
  double? bottomScrollOffset;
  Timer? scrollTimer;
  bool scrollNotified = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    topScrollOffset = null;
    bottomScrollOffset = null;
  }

  @override
  void dispose() {
    scrollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: {
        _CustomLongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<_CustomLongPressGestureRecognizer>(
          () => _CustomLongPressGestureRecognizer(),
          _registerCallbacks,
        ),
      },
      child: widget.child,
    );
  }

  void _registerCallbacks(_CustomLongPressGestureRecognizer recognizer) {
    recognizer.onLongPressMoveUpdate = (details) => _onLongPressMove(details);
    recognizer.onLongPressStart = (details) => _onLongPressStart(details);
    recognizer.onLongPressUp = _onLongPressEnd;
  }

  /// 命中检测：从全局坐标定位到包装在 AssetIndexWrapper 中的网格项
  AssetIndex? _getValueKeyAtPositon(Offset position) {
    final box = context.findAncestorRenderObjectOfType<RenderBox>();
    if (box == null) return null;

    final hitTestResult = BoxHitTestResult();
    final local = box.globalToLocal(position);
    if (!box.hitTest(hitTestResult, position: local)) return null;

    for (final path in hitTestResult.path) {
      final target = path.target;
      if (target is AssetIndexProxy) return target.index;
    }
    return null;
  }

  /// 长按开始：初始化边缘阈值、记录锚点与位置，并通知外层开始选择
  void _onLongPressStart(LongPressStartDetails event) {
    final height = context.size?.height;
    if (height != null && (topScrollOffset == null || bottomScrollOffset == null)) {
      topScrollOffset = height * scrollOffset;
      bottomScrollOffset = height - topScrollOffset!;
    }

    final initialHit = _getValueKeyAtPositon(event.globalPosition);
    anchorAsset = initialHit;
    _lastGlobalPosition = event.globalPosition;
    if (initialHit == null) return;
    widget.onStart?.call(anchorAsset!);
  }

  /// 长按结束：停止自动滚动并通知外层结束选择
  void _onLongPressEnd() {
    scrollNotified = false;
    scrollTimer?.cancel();
    widget.onEnd?.call();
  }

  /// 长按移动：
  /// - 检测是否进入边缘区域以启动自动滚动
  /// - 命中检测当前指尖下的索引并通知外层进入该资产
  void _onLongPressMove(LongPressMoveUpdateDetails event) {
    if (anchorAsset == null) return;
    if (topScrollOffset == null || bottomScrollOffset == null) return;

    final currentDy = event.localPosition.dy;
    _lastGlobalPosition = event.globalPosition;

    if (currentDy > bottomScrollOffset!) {
      scrollTimer ??= Timer.periodic(const Duration(milliseconds: 16), (_) {
        final ratio = _computeSpeedMultiplierFromGlobal(_lastGlobalPosition);
        widget.onScroll?.call(ScrollDirection.forward, ratio);
        final pos = _lastGlobalPosition;
        if (pos != null) {
          final hit = _getValueKeyAtPositon(pos);
          if (hit != null && assetUnderPointer != hit) {
            if (!scrollNotified) {
              scrollNotified = true;
              widget.onScrollStart?.call();
            }
            widget.onAssetEnter?.call(hit);
            assetUnderPointer = hit;
          }
        }
      });
    } else if (currentDy < topScrollOffset!) {
      scrollTimer ??= Timer.periodic(const Duration(milliseconds: 16), (_) {
        final ratio = _computeSpeedMultiplierFromGlobal(_lastGlobalPosition);
        widget.onScroll?.call(ScrollDirection.reverse, ratio);
        final pos = _lastGlobalPosition;
        if (pos != null) {
          final hit = _getValueKeyAtPositon(pos);
          if (hit != null && assetUnderPointer != hit) {
            if (!scrollNotified) {
              scrollNotified = true;
              widget.onScrollStart?.call();
            }
            widget.onAssetEnter?.call(hit);
            assetUnderPointer = hit;
          }
        }
      });
    } else {
      scrollTimer?.cancel();
      scrollTimer = null;
    }

    final currentlyTouchingAsset = _getValueKeyAtPositon(event.globalPosition);
    if (currentlyTouchingAsset == null) return;

    if (assetUnderPointer != currentlyTouchingAsset) {
      if (!scrollNotified) {
        scrollNotified = true;
        widget.onScrollStart?.call();
      }
      widget.onAssetEnter?.call(currentlyTouchingAsset);
      assetUnderPointer = currentlyTouchingAsset;
    }
  }

  double _computeSpeedMultiplierFromGlobal(Offset? global) {
    try {
      final box = context.findAncestorRenderObjectOfType<RenderBox>();
      if (box == null || topScrollOffset == null || bottomScrollOffset == null) return 1.0;
      if (global == null) return 1.0;
      final local = box.globalToLocal(global);
      final dy = local.dy;
      final height = box.size.height;
      if (dy > bottomScrollOffset!) {
        final denom = (height - bottomScrollOffset!).abs();
        if (denom <= 0) return 1.0;
        return ((dy - bottomScrollOffset!) / denom).clamp(0.0, 1.0);
      }
      if (dy < topScrollOffset!) {
        final denom = (topScrollOffset!).abs();
        if (denom <= 0) return 1.0;
        return ((topScrollOffset! - dy) / denom).clamp(0.0, 1.0);
      }
      return 0.0;
    } catch (_) {
      return 1.0;
    }
  }
}

class _CustomLongPressGestureRecognizer extends LongPressGestureRecognizer {
  @override
  void rejectGesture(int pointer) {
    acceptGesture(pointer);
  }
}

/// 将 row/section 索引携带到渲染树中，供命中检测提取
class AssetIndexWrapper extends SingleChildRenderObjectWidget {
  final int rowIndex;
  final int sectionIndex;

  const AssetIndexWrapper({required Widget super.child, required this.rowIndex, required this.sectionIndex, super.key});

  @override
  AssetIndexProxy createRenderObject(BuildContext context) {
    return AssetIndexProxy(index: AssetIndex(rowIndex: rowIndex, sectionIndex: sectionIndex));
  }

  @override
  void updateRenderObject(BuildContext context, AssetIndexProxy renderObject) {
    renderObject.index = AssetIndex(rowIndex: rowIndex, sectionIndex: sectionIndex);
  }
}

/// RenderObject 代理：承载 AssetIndex 信息
class AssetIndexProxy extends RenderProxyBox {
  AssetIndex index;
  AssetIndexProxy({required this.index});
}

/// 表示网格中的局部索引
class AssetIndex {
  final int rowIndex;
  final int sectionIndex;
  const AssetIndex({required this.rowIndex, required this.sectionIndex});
  @override
  bool operator ==(covariant AssetIndex other) => other.rowIndex == rowIndex && other.sectionIndex == sectionIndex;
  @override
  int get hashCode => rowIndex.hashCode ^ sectionIndex.hashCode;
}
