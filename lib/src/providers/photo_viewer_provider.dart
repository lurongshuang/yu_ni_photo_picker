import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import '../utils/page_status.dart';
import '../model/photo_picker_state.dart';
import '../model/photo_viewer_state.dart';
import '../service/photo_picker_service.dart';

/// 图片查看器配置
class PhotoViewerConfig {
  /// 初始显示的图片列表
  final List<ChoiceAssetEntity> assets;

  /// 初始显示的图片索引
  final int initialIndex;

  /// 是否启用选择模式
  final bool enableSelection;

  /// 最大选择数量
  final int maxSelection;

  /// 是否显示位置信息
  final bool showPositionInfo;

  /// 是否允许左右滑动
  final bool allowSwipe;

  /// 全局选中数量（所有相册的总选中数量）
  final int globalSelectedCount;

  /// 选择状态变化回调
  /// 参数：asset - 变化的资源, isSelected - 是否选中, globalSelectedCount - 更新后的全局选中数量
  final void Function(AssetEntity asset, bool isSelected, int globalSelectedCount)? onSelectionChanged;

  const PhotoViewerConfig({
    required this.assets,
    this.initialIndex = 0,
    this.enableSelection = true,
    this.maxSelection = 9,
    this.showPositionInfo = true,
    this.allowSwipe = true,
    this.globalSelectedCount = 0,
    this.onSelectionChanged,
  });
}

/// 图片查看器状态管理
class PhotoViewerNotifier extends StateNotifier<PhotoViewerState> {
  final PhotoViewerConfig config;
  late PageController pageController;
  Timer? _hideUITimer;

  PhotoViewerNotifier({required this.config})
    : super(const PhotoViewerState()) {
    _initialize();
  }

  void _initialize() {
    pageController = PageController(initialPage: config.initialIndex);

    // 从ChoiceAssetEntity中提取已选中的索引
    final selectedIndices = <int>{};
    for (int i = 0; i < config.assets.length; i++) {
      if (config.assets[i].isSelected) {
        selectedIndices.add(i);
      }
    }

    state = state.copyWith(
      assets: config.assets,
      currentIndex: config.initialIndex,
      pageIndex: config.initialIndex,
      isSelectionMode: config.enableSelection,
      selectedIndices: selectedIndices,
      canSwipe: config.allowSwipe,
      globalSelectedCount: config.globalSelectedCount,
      status: PageStatus.success,
    );
    // _startHideUITimer();
  }

  @override
  void dispose() {
    pageController.dispose();
    _hideUITimer?.cancel();
    super.dispose();
  }

  /// 切换到指定索引的图片
  void jumpToIndex(int index) {
    if (index >= 0 && index < state.assets.length) {
      pageController.jumpToPage(index);
      state = state.copyWith(currentIndex: index, pageIndex: index);
    }
  }

  /// 页面变化时更新当前索引
  void onPageChanged(int index) {
    state = state.copyWith(currentIndex: index, pageIndex: index);

    // 预加载相邻图片的缩略图
    _preloadAdjacentThumbnails(index);
  }

  /// 预加载相邻图片的缩略图
  void _preloadAdjacentThumbnails(int currentIndex) {
    const preloadRange = 2; // 预加载前后2张图片
    final thumbnailSize = ThumbnailSize(800, 600); // 高质量缩略图尺寸

    // 计算预加载范围
    final startIndex = (currentIndex - preloadRange).clamp(
      0,
      state.assets.length - 1,
    );
    final endIndex = (currentIndex + preloadRange).clamp(
      0,
      state.assets.length - 1,
    );

    // 预加载指定范围内的缩略图
    for (int i = startIndex; i <= endIndex; i++) {
      if (i != currentIndex) {
        // 跳过当前图片，避免重复加载
        final asset = state.assets[i].asset;
        // 异步预加载，不等待结果
        PhotoPickerService.getThumbnail(asset, thumbnailSize);
      }
    }
  }

  /// 切换选择状态
  void toggleSelection(int? index) {
    if (!config.enableSelection) return;

    final targetIndex = index ?? state.currentIndex;
    if (targetIndex < 0 || targetIndex >= state.assets.length) return;

    final newSelectedIndices = Set<int>.from(state.selectedIndices);
    bool wasSelected = newSelectedIndices.contains(targetIndex);

    if (wasSelected) {
      newSelectedIndices.remove(targetIndex);
    } else {
      if (newSelectedIndices.length < config.maxSelection) {
        newSelectedIndices.add(targetIndex);
      } else {
        // 已达到最大选择数量
        if (config.maxSelection == 1) {
          // 单选模式：用当前项替换之前的选中项
          newSelectedIndices
            ..clear()
            ..add(targetIndex);
        } else {
          return; // 多选模式达到上限，不执行操作
        }
      }
    }

    state = state.copyWith(selectedIndices: newSelectedIndices);

    // 计算更新后的全局选中数量
    int newGlobalSelectedCount;
    if (config.maxSelection == 1) {
      // 单选模式：全局选中数量固定为 0 或 1
      newGlobalSelectedCount = state.selectedIndices.isNotEmpty ? 1 : 0;
    } else {
      // 多选模式：基于当前选择集合大小的增减
      newGlobalSelectedCount = wasSelected
          ? (state.globalSelectedCount - 1).clamp(0, double.infinity).toInt()
          : state.globalSelectedCount + 1;
    }

    // 调用回调函数同步状态到 PhotoPicker，并传递更新后的全局选中数量
    config.onSelectionChanged?.call(
      state.assets[targetIndex].asset,
      !wasSelected,
      newGlobalSelectedCount,
    );
  }

  /// 切换当前图片的选择状态
  void toggleCurrentSelection() {
    toggleSelection(state.currentIndex);
  }

  /// 清空选择
  void clearSelection() {
    state = state.copyWith(selectedIndices: const {});
  }

  /// 全选
  void selectAll() {
    if (!config.enableSelection) return;

    final maxSelectCount = config.maxSelection.clamp(0, state.assets.length);
    final selectedIndices = Set<int>.from(
      List.generate(maxSelectCount, (index) => index),
    );

    state = state.copyWith(selectedIndices: selectedIndices);
  }

  /// 切换UI显示状态
  void toggleUIVisibility() {
    // state = state.copyWith(isUIVisible: !state.isUIVisible);
    // if (state.isUIVisible) {
    //   _startHideUITimer();
    // } else {
    //   _hideUITimer?.cancel();
    // }
  }

  /// 显示UI
  void showUI() {
    if (!state.isUIVisible) {
      state = state.copyWith(isUIVisible: true);
    }
    // _startHideUITimer();
  }

  /// 隐藏UI
  void hideUI() {
    state = state.copyWith(isUIVisible: false);
    _hideUITimer?.cancel();
  }

  

  /// 更新缩放比例
  void updateScale(double scale) {
    state = state.copyWith(
      scale: scale,
      canSwipe: scale <= 1.0, // 缩放时禁用滑动
    );
  }

  /// 重置缩放
  void resetScale() {
    state = state.copyWith(scale: 1.0, canSwipe: config.allowSwipe);
  }

  /// 上一张图片
  void previousImage() {
    if (state.hasPrevious && state.canSwipe) {
      final newIndex = state.currentIndex - 1;
      pageController.animateToPage(
        newIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// 下一张图片
  void nextImage() {
    if (state.hasNext && state.canSwipe) {
      final newIndex = state.currentIndex + 1;
      pageController.animateToPage(
        newIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// 设置加载状态
  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  /// 设置错误状态
  void setError(String errorMessage) {
    state = state.copyWith(
      status: PageStatus.error,
      errorMessage: errorMessage,
    );
  }

  /// 获取选中的图片列表
  List<AssetEntity> getSelectedAssets() {
    return state.selectedAssets;
  }

  /// 检查是否可以选择更多
  bool canSelectMore() {
    return state.selectedCount < config.maxSelection;
  }

  /// 更新全局选中数量
  void updateGlobalSelectedCount(int count) {
    state = state.copyWith(globalSelectedCount: count);
  }

  /// 处理发送操作
  void handleSend() {
    final selectedAssets = getSelectedAssets();
    if (selectedAssets.isNotEmpty) {
      // 这里可以添加发送逻辑，比如回调给上层页面
      // 或者触发一个事件
    }
  }
}

/// 图片查看器Provider
final photoViewerProvider = StateNotifierProvider.family<
  PhotoViewerNotifier,
  PhotoViewerState,
  PhotoViewerConfig
>((ref, config) => PhotoViewerNotifier(config: config));

