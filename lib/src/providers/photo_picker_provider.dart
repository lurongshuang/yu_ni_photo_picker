import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:yuni_widget/yuni_widget.dart';
import '../utils/page_status.dart';
import '../config/picker_file.dart';
import '../model/photo_picker_state.dart';
import '../config/photo_picker_config.dart';
import '../service/photo_picker_service.dart';
import '../components/drag_selectable_grid_view.dart';

import '../constants/constants.dart';
import '../page/photo_viewer_page.dart';

class PhotoPickerNotifier extends StateNotifier<PhotoPickerState> {
  final PhotoPickerConfig config;
  late final DragSelectionController _selectionController;
  bool _recalculatingSize = false;

  PhotoPickerNotifier({required this.config})
    : super(const PhotoPickerState()) {
    // 初始化选择控制器
    _selectionController = DragSelectionController(
      selectionMode:
          config.allowMultiple ? SelectionMode.multiple : SelectionMode.single,
      maxSelection: config.maxAssets,
      onSelectionChanged: _onSelectionChanged,
      onItemSelectionChanged: _onItemSelectionChanged,
    );
  }

  final Map<AssetCategory, ScrollController> _controllers = {};
  AssetCategory? _attachedCategory;

  ScrollController _getOrCreateController(AssetCategory category) {
    return _controllers.putIfAbsent(category, () => ScrollController());
  }

  ScrollController get scrollController =>
      _getOrCreateController(state.currentCategory);

  // 获取选择控制器
  DragSelectionController get selectionController => _selectionController;

  List<ChoiceAssetEntity> _applyCategoryFilter(
    List<ChoiceAssetEntity> base,
    AssetCategory category,
  ) {
    switch (category) {
      case AssetCategory.video:
        return base
            .where(
              (e) =>
                  e.asset.type == AssetType.video ||
                  e.asset.type == AssetType.audio,
            )
            .toList();
      case AssetCategory.image:
        return base
            .where(
              (e) => e.asset.type == AssetType.image && !e.asset.isLivePhoto,
            )
            .toList();
      case AssetCategory.live:
        return base.where((e) => e.asset.isLivePhoto).toList();
      case AssetCategory.all:
        return base;
    }
  }

  void setCategory(AssetCategory category) {
    final display = _applyCategoryFilter(state.allAssets, category);
    // 先更新可见列表为当前分类
    final currentAlbumSelectedCount = display.where((a) => a.isSelected).length;
    final isAllSelected =
        currentAlbumSelectedCount == display.length && display.isNotEmpty;
    state = state.copyWith(
      currentCategory: category,
      assets: display,
      allSelected: isAllSelected,
      selectedCount: state.globalSelectedAssets.length,
    );

    _switchActiveController(category);

    // 再同步选择控制器索引，确保回调使用最新的 state.assets
    final selectedIndices = <int>{};
    for (int i = 0; i < display.length; i++) {
      if (display[i].isSelected) selectedIndices.add(i);
    }
    _selectionController.setSelection(selectedIndices);
  }

  // 选择状态变化回调
  void _onSelectionChanged(Set<int> selectedIndices) {
    // 获取当前相册中选中的资源
    final currentAlbumSelectedAssets =
        selectedIndices
            .where((index) => index >= 0 && index < state.assets.length)
            .map((index) => state.assets[index].asset)
            .toList();

    // 更新本地选择状态
    final updatedAssets = List<ChoiceAssetEntity>.from(state.assets);
    for (int i = 0; i < updatedAssets.length; i++) {
      updatedAssets[i].isSelected = selectedIndices.contains(i);
    }

    // 更新全局选择状态
    // 多选：保留其他相册的选中项，合并当前相册选中项
    // 单选：全局最多1个；当当前分类没有可见选中时，若之前的选中不属于当前分类，则保留之前的选中
    final currentAlbumAssetIds =
        state.assets.map((asset) => asset.asset.id).toSet();
    final otherAlbumsSelectedAssets =
        state.globalSelectedAssets
            .where((asset) => !currentAlbumAssetIds.contains(asset.id))
            .toList();

    List<AssetEntity> newGlobalSelectedAssets;
    if (config.allowMultiple) {
      newGlobalSelectedAssets = [
        ...otherAlbumsSelectedAssets,
        ...currentAlbumSelectedAssets,
      ];
    } else {
      if (currentAlbumSelectedAssets.isEmpty) {
        // 当前分类没有选中项：判断之前的选中是否属于当前分类
        final previousInCurrent = state.globalSelectedAssets.any(
          (asset) => currentAlbumAssetIds.contains(asset.id),
        );
        if (previousInCurrent) {
          // 用户在当前分类取消了选中：清空全局选中
          newGlobalSelectedAssets = const [];
        } else {
          // 切换到不包含已选项的分类：保留之前的选中
          newGlobalSelectedAssets = List<AssetEntity>.from(
            state.globalSelectedAssets,
          );
        }
      } else {
        // 当前分类有选中：替换全局为当前选中
        newGlobalSelectedAssets = currentAlbumSelectedAssets;
      }
    }

    // 计算当前相册是否全选
    final currentAlbumSelectedCount =
        updatedAssets.where((asset) => asset.isSelected).length;
    final isAllSelected =
        currentAlbumSelectedCount == updatedAssets.length &&
        updatedAssets.isNotEmpty;

    // 单选模式下需要同步 allAssets 的选中标记为全局唯一选中
    List<ChoiceAssetEntity> updatedAllAssets = state.allAssets;
    if (!config.allowMultiple) {
      final selectedIds = newGlobalSelectedAssets.map((e) => e.id).toSet();
      updatedAllAssets =
          state.allAssets
              .map(
                (item) => ChoiceAssetEntity(
                  asset: item.asset,
                  isSelected: selectedIds.contains(item.asset.id),
                ),
              )
              .toList();
    }

    state = state.copyWith(
      allAssets: updatedAllAssets,
      assets: updatedAssets,
      selectedCount: newGlobalSelectedAssets.length,
      globalSelectedAssets: newGlobalSelectedAssets,
      allSelected: isAllSelected,
    );
    _scheduleRecalculateSelectedSize();
  }

  // 单个项目选择状态变化回调
  void _onItemSelectionChanged(int index, bool isSelected) {
    if (index >= 0 && index < state.assets.length) {
      final asset = state.assets[index];
      asset.isSelected = isSelected;

      // 触发整体选择状态更新
      _onSelectionChanged(_selectionController.selectedIndices);
    }
  }

  Future<void> initialization(BuildContext context) async {
    _switchActiveController(state.currentCategory);
    state = state.copyWith(status: PageStatus.loading);
    loadAssets();
  }

  void _switchActiveController(AssetCategory category) {
    if (_attachedCategory != null) {
      final old = _controllers[_attachedCategory!];
      old?.removeListener(_onScroll);
    }
    final controller = _getOrCreateController(category);
    controller.removeListener(_onScroll);
    controller.addListener(_onScroll);
    _attachedCategory = category;
  }

  void _onScroll() {
    final controller = scrollController;
    if (!controller.hasClients) return;
    final position = controller.position;
    const preloadDistance = 800.0;
    if (position.pixels >= position.maxScrollExtent - preloadDistance) {
      if (state.hasMore && !state.isLoadingMore) {
        final nextPageAssets =
            state.assets
                .skip(state.assets.length - 10)
                .map((e) => e.asset)
                .toList();
        PhotoPickerService.preloadThumbnails(
          nextPageAssets,
          defaultAssetGridPreviewSize,
        );
        loadMore();
      }
    }
  }

  @override
  void dispose() {
    for (final entry in _controllers.entries) {
      entry.value.removeListener(_onScroll);
      entry.value.dispose();
    }
    _selectionController.dispose();
    super.dispose();
  }

  Future<void> loadAssets() async {
    try {
      // 获取所有相册
      final allPaths = await PhotoPickerService.getAllAlbumPaths(
        requestType: config.requestType,
      );

      if (allPaths.isEmpty) {
        state = state.copyWith(
          status: PageStatus.empty,
          assets: const [],
          recentPath: null,
          albumPaths: const [],
          currentAlbum: null,
          page: 0,
          totalCount: 0,
          hasMore: false,
        );
        return;
      }

      final recentPath = allPaths.first;

      // 读取总数与第一页
      final total = await PhotoPickerService.getAssetCount(recentPath);
      final firstPage = await PhotoPickerService.loadAssetsPage(
        path: recentPath,
        page: 0,
        size: defaultPageSize,
      );

      // 确保没有重复的资源，并恢复选中状态
      final uniqueAssets = <ChoiceAssetEntity>[];
      final assetIds = <String>{};
      final selectedIndices = <int>{};

      for (int i = 0; i < firstPage.length; i++) {
        final asset = firstPage[i];
        if (!assetIds.contains(asset.id)) {
          final isSelected = state.globalSelectedAssets.any(
            (selected) => selected.id == asset.id,
          );
          uniqueAssets.add(
            ChoiceAssetEntity(asset: asset, isSelected: isSelected),
          );
          assetIds.add(asset.id);

          // 如果该资源被选中，记录其索引
          if (isSelected) {
            selectedIndices.add(i);
          }
        }
      }

      final displayAssets = _applyCategoryFilter(
        uniqueAssets,
        state.currentCategory,
      );
      // 计算当前相册是否全选
      final currentAlbumSelectedCount =
          displayAssets.where((asset) => asset.isSelected).length;
      final isAllSelected =
          currentAlbumSelectedCount == displayAssets.length &&
          displayAssets.isNotEmpty;

      // 先设置最新的展示列表
      state = state.copyWith(
        allAssets: uniqueAssets,
        assets: displayAssets,
        recentPath: recentPath,
        albumPaths: allPaths,
        currentAlbum: recentPath,
        page: 0,
        totalCount: total,
        hasMore: uniqueAssets.length < total,
        status: uniqueAssets.isEmpty ? PageStatus.empty : PageStatus.success,
        selectedCount: state.globalSelectedAssets.length,
        allSelected: isAllSelected,
      );

      // 再更新选择控制器索引以触发正确的回调
      final displaySelectedIndices = <int>{};
      for (int i = 0; i < displayAssets.length; i++) {
        if (displayAssets[i].isSelected) {
          displaySelectedIndices.add(i);
        }
      }
      _selectionController.setSelection(displaySelectedIndices);
      _scheduleRecalculateSelectedSize();
    } catch (e) {
      state = state.copyWith(
        status: PageStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// 切换相册
  Future<void> switchAlbum(AssetPathEntity album) async {
    if (state.currentAlbum?.id == album.id) return;

    try {
      state = state.copyWith(status: PageStatus.loading);

      // 读取新相册的总数与第一页
      final total = await PhotoPickerService.getAssetCount(album);
      final firstPage = await PhotoPickerService.loadAssetsPage(
        path: album,
        page: 0,
        size: defaultPageSize,
      );

      // 确保没有重复的资源，并恢复选中状态
      final uniqueAssets = <ChoiceAssetEntity>[];
      final assetIds = <String>{};
      final selectedIndices = <int>{};

      for (int i = 0; i < firstPage.length; i++) {
        final asset = firstPage[i];
        if (!assetIds.contains(asset.id)) {
          final isSelected = state.globalSelectedAssets.any(
            (selected) => selected.id == asset.id,
          );
          uniqueAssets.add(
            ChoiceAssetEntity(asset: asset, isSelected: isSelected),
          );
          assetIds.add(asset.id);

          // 如果该资源被选中，记录其索引
          if (isSelected) {
            selectedIndices.add(i);
          }
        }
      }

      final displayAssets = _applyCategoryFilter(
        uniqueAssets,
        state.currentCategory,
      );
      final currentAlbumSelectedCount =
          displayAssets.where((asset) => asset.isSelected).length;
      final isAllSelected =
          currentAlbumSelectedCount == displayAssets.length &&
          displayAssets.isNotEmpty;

      // 先设置最新的展示列表
      state = state.copyWith(
        allAssets: uniqueAssets,
        assets: displayAssets,
        currentAlbum: album,
        page: 0,
        totalCount: total,
        hasMore: uniqueAssets.length < total,
        status: uniqueAssets.isEmpty ? PageStatus.empty : PageStatus.success,
        allSelected: isAllSelected,
        selectedCount: state.globalSelectedAssets.length,
      );

      // 再更新选择控制器索引以触发正确的回调
      final displaySelectedIndices = <int>{};
      for (int i = 0; i < displayAssets.length; i++) {
        if (displayAssets[i].isSelected) displaySelectedIndices.add(i);
      }
      _selectionController.setSelection(displaySelectedIndices);
      _scheduleRecalculateSelectedSize();
    } catch (e) {
      state = state.copyWith(
        status: PageStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    // 避免重复加载或无更多
    if (state.isLoadingMore || !state.hasMore || state.recentPath == null) {
      return;
    }

    try {
      state = state.copyWith(isLoadingMore: true);
      final nextPage = state.page + 1;

      final pageList = await PhotoPickerService.loadAssetsPage(
        path: state.currentAlbum!,
        page: nextPage,
        size: defaultPageSize,
      );

      if (pageList.isEmpty) {
        state = state.copyWith(hasMore: false, isLoadingMore: false);
        return;
      }

      final newAssets = List<ChoiceAssetEntity>.from(state.allAssets);

      // 检查当前是否处于全选状态（基于已加载的数据和state.allSelected）
      final currentLoadedSelectedCount =
          newAssets.where((asset) => asset.isSelected).length;
      final wasAllSelected =
          state.allSelected &&
          currentLoadedSelectedCount == newAssets.length &&
          newAssets.isNotEmpty;

      List<AssetEntity> newGlobalSelected = List.from(
        state.globalSelectedAssets,
      );

      // 检查并避免重复添加相同的资源，并恢复选中状态
      final existingIds = newAssets.map((e) => e.asset.id).toSet();

      for (final asset in pageList) {
        if (!existingIds.contains(asset.id)) {
          bool isSelected = state.globalSelectedAssets.any(
            (selected) => selected.id == asset.id,
          );

          // 如果之前是全选状态，且还没达到最大选择数，新加载的数据也应该被选中
          if (!isSelected &&
              wasAllSelected &&
              newGlobalSelected.length < config.maxAssets) {
            isSelected = true;
            newGlobalSelected.add(asset);
          }

          newAssets.add(
            ChoiceAssetEntity(asset: asset, isSelected: isSelected),
          );
          existingIds.add(asset.id);
        }
      }

      final displayAssets = _applyCategoryFilter(
        newAssets,
        state.currentCategory,
      );
      final loadedCount = newAssets.length;
      final hasMore = loadedCount < state.totalCount;

      // 计算当前相册是否全选
      // 确保只有当前相册的所有资源都被选中，且没有选中其他相册的资源时，才显示为全选状态
      final currentAlbumSelectedCount =
          displayAssets.where((asset) => asset.isSelected).length;
      // 检查全局选中列表中是否只包含当前相册的资源
      final currentAlbumAssetIds =
          newAssets.map((asset) => asset.asset.id).toSet();
      final globalSelectedFromCurrentAlbum =
          newGlobalSelected
              .where((asset) => currentAlbumAssetIds.contains(asset.id))
              .length;
      final isAllSelected =
          currentAlbumSelectedCount == displayAssets.length &&
          displayAssets.isNotEmpty &&
          globalSelectedFromCurrentAlbum == newGlobalSelected.length;

      // 先设置最新的展示列表
      state = state.copyWith(
        allAssets: newAssets,
        assets: displayAssets,
        page: nextPage,
        hasMore: hasMore,
        isLoadingMore: false,
        status: PageStatus.success,
        allSelected: isAllSelected,
        selectedCount: newGlobalSelected.length,
        globalSelectedAssets: newGlobalSelected,
      );

      // 再更新选择控制器索引以触发正确的回调
      final displaySelectedIndices = <int>{};
      for (int i = 0; i < displayAssets.length; i++) {
        if (displayAssets[i].isSelected) displaySelectedIndices.add(i);
      }
      _selectionController.setSelection(displaySelectedIndices);
      _scheduleRecalculateSelectedSize();
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        status: PageStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void toggleSelect(AssetEntity asset, {bool? targetSelected}) {
    final assets = state.assets;
    final index = assets.indexWhere((item) => item.asset.id == asset.id);

    final isSelect = _selectionController.isSelected(index);
    if (state.selectedCount >= config.maxAssets && !isSelect) {
      YToastHelper.toast("最多只能选择${config.maxAssets}");
      return;
    }
    if (index >= 0) {
      // 使用选择控制器处理选择逻辑
      _selectionController.toggleSelection(
        index,
        targetSelected: targetSelected,
      );
    }
  }

  void toggleSendOriginal() {
    state = state.copyWith(sendOriginal: !state.sendOriginal);
  }

  void _scheduleRecalculateSelectedSize() {
    if (_recalculatingSize) return;
    _recalculatingSize = true;
    Future(() async {
      if (!mounted) {
        return;
      }
      try {
        final total = await _recalculateSelectedSize();
        state = state.copyWith(totalSelectedSize: total);
      } finally {
        _recalculatingSize = false;
      }
    });
  }

  Future<int> _recalculateSelectedSize() async {
    int sum = 0;
    for (final asset in state.globalSelectedAssets) {
      try {
        final file = await asset.originFile;
        if (file != null) {
          sum += await file.length();
        }
      } catch (_) {}
    }
    return sum;
  }

  void previewSelected(BuildContext context) {
    final selected = state.globalSelectedAssets;
    if (selected.isEmpty) return;
    final choice =
        selected
            .map((e) => ChoiceAssetEntity(asset: e, isSelected: true))
            .toList();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => PhotoViewerPage(
              assets: choice,
              pickerConfig: config,
              initialIndex: 0,
              enableSelection: true,
              maxSelection: config.maxAssets,
              globalSelectedCount: state.selectedCount,
              onSelectionChanged: (asset, isSelected, globalSelectedCount) {
                toggleSelect(asset, targetSelected: isSelected);
              },
              onSend: () {
                Navigator.of(context).pop();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    confirm(context);
                  }
                });
              },
            ),
      ),
    );
  }

  int get selectedCount => state.globalSelectedAssets.length;

  Future<dynamic> confirm(BuildContext context) async {
    if (config.allowMultiple) {
      final selectedAssets = List<AssetEntity>.from(state.globalSelectedAssets);
      final files = await Future.wait(
        selectedAssets.map(PhotoPickerService.toPhotoPickerFile),
      );
      if (!context.mounted) {
        return;
      }
      final list = files.whereType<PhotoPickerFile>().toList();
      for (int i = 0; i < list.length; i++) {
        final f = list[i];
        f.sendOriginal = state.sendOriginal;
        final asset = selectedAssets[i];
        final toggle = state.liveVideoUploadMap[asset.id];
        if (f.isLivePhoto) {
          f.sendLiveVideo = toggle ?? true;
        } else {
          f.sendLiveVideo = false;
        }
      }
      return Navigator.pop(context, list);
    } else {
      final asset = state.globalSelectedAssets.first;
      final file = await PhotoPickerService.toPhotoPickerFile(asset);
      if (!context.mounted) {
        return;
      }
      if (file != null) {
        file.sendOriginal = state.sendOriginal;
        final toggle = state.liveVideoUploadMap[asset.id];
        if (file.isLivePhoto) {
          file.sendLiveVideo = toggle ?? true;
        } else {
          file.sendLiveVideo = false;
        }
      }
      return Navigator.pop(context, file);
    }
  }

  ///全选/取消全选 当前相册的item
  void switchCheckAll() {
    if (!config.allowMultiple) return; // 单选模式不支持全选

    // 使用选择控制器处理全选/取消全选
    _selectionController.toggleSelectAll(state.assets.length);
  }

  /// 开始滑动选择
  void startDragSelection(int index) {
    if (!config.allowMultiple) return; // 单选模式不支持滑动选择
    _selectionController.startDragSelection(index);
  }

  /// 处理滑动选择过程中的位置变化
  void updateDragSelection(int index) {
    _selectionController.updateDragSelection(index);
  }

  /// 结束滑动选择
  void endDragSelection() {
    _selectionController.endDragSelection();
  }

  /// 切换是否上传实况/动图的视频部分
  void toggleLiveVideo(AssetEntity asset) {
    final map = Map<String, bool>.from(state.liveVideoUploadMap);
    final current = map[asset.id];
    final next = !(current ?? true);
    map[asset.id] = next;
    state = state.copyWith(liveVideoUploadMap: map);
  }

  void jumpToViewer(BuildContext context, AssetEntity asset) {
    // 找到当前资源在列表中的索引
    final index = state.assets.indexWhere((item) => item.asset.id == asset.id);
    if (index == -1) return;

    // 导航到查看大图页面
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => PhotoViewerPage(
              assets: state.assets,
              pickerConfig: config,
              initialIndex: index,
              // 单选模式也启用"右上角选中组件"（单选按钮），但将最大选择数量限制为 1
              enableSelection: true,
              maxSelection: config.allowMultiple ? config.maxAssets : 1,
              globalSelectedCount: state.selectedCount,
              // 传递全局选中数量
              onSelectionChanged: (asset, isSelected, globalSelectedCount) {
                // 同步选择状态到PhotoPicker，显式传入目标选中状态
                toggleSelect(asset, targetSelected: isSelected);
                // globalSelectedCount 参数会在 toggleSelect 触发 _onSelectionChanged 后更新
                // 但由于是异步的，我们传递的是更新后的值（通过回调参数）
              },
              onSend: () {
                // 先关闭查看器
                Navigator.of(context).pop();
                // 在下一帧执行确认，确保查看器页面完全出栈后再进行二次 pop
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    confirm(context);
                  }
                });
              },
            ),
      ),
    );
  }
}

final photoPickerProvider = StateNotifierProvider.autoDispose
    .family<PhotoPickerNotifier, PhotoPickerState, PhotoPickerConfig>((
      ref,
      config,
    ) {
      return PhotoPickerNotifier(config: config);
    });
