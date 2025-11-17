import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../utils/page_status.dart';
import '../components/app_bar/photos_app_bar.dart';
import '../components/image_view/image_error.dart';
import '../model/photo_picker_state.dart';
import '../model/photo_viewer_state.dart';
import '../providers/photo_viewer_provider.dart';
import '../components/radio_icon_widget.dart';
import 'package:yuni_widget/yuni_widget.dart';
import '../widget/photo_viewer_item_widget.dart';
import '../config/photo_picker_config.dart';
import '../providers/photo_picker_provider.dart';
import 'dart:io' show Platform;
import '../components/live_photo_icon_widget.dart';
import 'package:motion_photos/motion_photos.dart';

/// 图片查看器页面
class PhotoViewerPage extends ConsumerStatefulWidget {
  /// 图片列表
  final List<ChoiceAssetEntity> assets;

  /// 初始显示的图片索引
  final int initialIndex;

  /// 是否启用选择模式
  final bool enableSelection;

  /// 最大选择数量
  final int maxSelection;

  /// 全局选中数量（所有相册的总选中数量）
  final int globalSelectedCount;

  /// 发送按钮回调
  final VoidCallback? onSend;

  /// 选择变化回调
  /// 参数：asset - 变化的资源, isSelected - 是否选中, globalSelectedCount - 更新后的全局选中数量
  final void Function(
    AssetEntity asset,
    bool isSelected,
    int globalSelectedCount,
  )?
  onSelectionChanged;
  final PhotoPickerConfig pickerConfig;

  const PhotoViewerPage({
    super.key,
    required this.assets,
    required this.pickerConfig,
    this.initialIndex = 0,
    this.enableSelection = true,
    this.maxSelection = 9,
    this.globalSelectedCount = 0,
    this.onSend,
    this.onSelectionChanged,
  });

  @override
  ConsumerState<PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends ConsumerState<PhotoViewerPage> {
  late PhotoViewerConfig _config;

  @override
  void initState() {
    super.initState();
    _config = PhotoViewerConfig(
      assets: widget.assets,
      initialIndex: widget.initialIndex,
      enableSelection: widget.enableSelection,
      maxSelection: widget.maxSelection,
      globalSelectedCount: widget.globalSelectedCount,
      onSelectionChanged:
          widget.onSelectionChanged != null
              ? (asset, isSelected, globalSelectedCount) {
                // 先调用外层回调，同步选择到 PhotoPicker（列表页）
                widget.onSelectionChanged?.call(
                  asset,
                  isSelected,
                  globalSelectedCount,
                );
                // 更新查看页的计数显示
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    final notifier = ref.read(
                      photoViewerProvider(_config).notifier,
                    );
                    notifier.updateGlobalSelectedCount(globalSelectedCount);
                  }
                });
              }
              : null,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(photoViewerProvider(_config));
    final notifier = ref.read(photoViewerProvider(_config).notifier);

    return Scaffold(
      backgroundColor: YuniWidgetConfig.instance.colors.onSurface,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context, state, notifier),
      body: _buildBody(context, state, notifier),
    );
  }

  /// 构建应用栏
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    PhotoViewerState state,
    PhotoViewerNotifier notifier,
  ) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: AnimatedOpacity(
        opacity: state.isUIVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: PhotosAppBar(
          bgColor: YuniWidgetConfig.instance.colors.onBackground.withValues(
            alpha: 0.5,
          ),
          customTitleWidget: _buildPositionInfo(state),
          leadingColor: YuniWidgetConfig.instance.colors.surface,
          sysOverlayStyle: SystemUiOverlayStyle.dark,
          actions: [
            if (widget.enableSelection)
              ..._buildSelectionActions(state, notifier),
          ],
        ),
      ),
    );
  }

  /// 构建选择相关的操作按钮
  List<Widget> _buildSelectionActions(
    PhotoViewerState state,
    PhotoViewerNotifier notifier,
  ) {
    return [
      // 选择/取消选择按钮
      GestureDetector(
        onTap: () {
          notifier.toggleCurrentSelection();
          notifier.showUI(); // 点击后重新显示UI
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          child: RadioIconWidget(selected: state.isCurrentSelected, size: 24),
        ),
      ),
      const SizedBox(width: 8),
    ];
  }

  /// 构建发送按钮
  Widget _buildSendButton(
    PhotoViewerNotifier notifier,
    PhotoViewerState state,
  ) {
    final config = YuniWidgetConfig.instance;

    return YTapped(
      onTap: () {
        notifier.handleSend();
        widget.onSend?.call();
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: config.spacing.md,
          vertical: config.spacing.xs,
        ),
        decoration: BoxDecoration(
          color: config.colors.primary,
          borderRadius: config.radius.borderFull,
          boxShadow: [
            BoxShadow(
              color: config.colors.onSurface.withValues(alpha: 0.1),
              blurRadius: config.spacing.lg,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            YText(
              widget.pickerConfig.confirmButtonText,
              style: config.textStyles.bodyMediumBold.copyWith(
                color: config.colors.onPrimary,
                height: 1,
              ),
            ),
            YSpacing.widthSm(),
            Container(
              padding: EdgeInsets.all(config.spacing.sm),
              decoration: BoxDecoration(
                color: config.colors.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: YText(
                  '${state.totalSelectedCount}',
                  style: config.textStyles.bodySmallBold.copyWith(
                    color: config.colors.onPrimary,
                    height: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建主体内容
  Widget _buildBody(
    BuildContext context,
    PhotoViewerState state,
    PhotoViewerNotifier notifier,
  ) {
    final pickerState = ref.watch(photoPickerProvider(widget.pickerConfig));
    final pickerNotifier = ref.read(
      photoPickerProvider(widget.pickerConfig).notifier,
    );
    if (state.status == PageStatus.loading) {
      return const Center(child: YLoading());
    }

    if (state.status == PageStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const ImageError(),
            YSpacing.heightLg(),
            YText(
              state.errorMessage ?? '加载失败',
              style: YuniWidgetConfig.instance.textStyles.bodyLargeRegular
                  .copyWith(color: YuniWidgetConfig.instance.colors.onPrimary),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // 图片查看器
        Positioned.fill(child: _buildPhotoGallery(state, notifier)),
        // 手势检测层
        // _buildGestureLayer(notifier),
        Positioned(
          left: 16,
          top: 16 + MediaQuery.of(context).padding.top,
          child: SafeArea(
            child: FutureBuilder<bool>(
              future: _isMotionPhoto(state.currentAsset),
              builder: (context, snapshot) {
                final visible = snapshot.data ?? false;
                if (!visible) return const SizedBox.shrink();
                return Stack(
                  children: [
                    LivePhotoWidget(
                      iconSize: 24,
                      isOpen:
                          state.currentAsset == null
                              ? true
                              : (pickerState.liveVideoUploadMap[state
                                      .currentAsset!
                                      .id] ??
                                  true),
                    ),
                    YTapped(
                      onTap: () {
                        final asset = state.currentAsset;
                        if (asset != null) {
                          pickerNotifier.toggleLiveVideo(asset);
                        }
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        color: Colors.transparent,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        // if (widget.pickerConfig.showOriginalToggle)
        //   Positioned(
        //     left: 0,
        //     right: 0,
        //     bottom: 16 + MediaQuery.of(context).padding.bottom,
        //     child: Center(
        //       child: _buildOriginalToggle(pickerState, pickerNotifier),
        //     ),
        //   ),
        // if (state.totalSelectedCount > 0)
        //   Positioned(
        //     right: 16,
        //     bottom: 16 + MediaQuery.of(context).padding.bottom,
        //     child: _buildSendButton(notifier, state),
        //   ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildBottomBar(pickerState, pickerNotifier, notifier, state),
        ),
      ],
    );
  }

  _buildBottomBar(
    PhotoPickerState pickerState,
    PhotoPickerNotifier pickerNotifier,
    notifier,
    state,
  ) {
    final paddingBottom = MediaQuery.of(context).padding.bottom;
    final config = YuniWidgetConfig.instance;

    return Container(
      padding: EdgeInsets.only(
        bottom: paddingBottom + 10,
        top: 10,
        left: 10,
        right: 10,
      ),
      alignment: Alignment.center,
      child: Row(
        children: [
          if (widget.pickerConfig.showOriginalToggle &&
              state.totalSelectedCount > 0)
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildOriginalToggle(pickerState, pickerNotifier),
              ),
            ),
          if (state.totalSelectedCount > 0)
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: _buildSendButton(notifier, state),
              ),
            ),
        ],
      ),
    );
  }

  Future<bool> _isMotionPhoto(AssetEntity? asset) async {
    if (Platform.isIOS) {
      return asset?.isLivePhoto ?? false;
    }
    if (asset == null || asset.type != AssetType.image) return false;
    final file = await asset.originFile;
    if (file == null) return false;
    try {
      if (!await file.exists()) return false;
      final MotionPhotos motionPhotos = MotionPhotos(file.path);
      return motionPhotos.isMotionPhoto();
    } catch (_) {
      return false;
    }
  }

  /// 构建图片画廊
  Widget _buildPhotoGallery(
    PhotoViewerState state,
    PhotoViewerNotifier notifier,
  ) {
    return PhotoViewGallery.builder(
      // scrollPhysics:
      //     state.canSwipe
      //         ? const BouncingScrollPhysics()
      //         : const NeverScrollableScrollPhysics(),
      builder: (BuildContext context, int index) {
        final asset = state.assets[index].asset;

        return PhotoViewGalleryPageOptions.customChild(
          child: PhotoViewerItemWidget(
            asset: asset,
            // onTap: () {
            //   notifier.toggleUIVisibility();
            // },
          ),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 4,
          initialScale: PhotoViewComputedScale.contained,
          heroAttributes: PhotoViewHeroAttributes(tag: 'photo_${asset.id}'),
          onScaleEnd: (context, details, controllerValue) {
            notifier.updateScale(controllerValue.scale ?? 1.0);
          },
        );
      },
      itemCount: state.assets.length,
      loadingBuilder: (context, event) => const Center(child: YLoading()),
      backgroundDecoration: BoxDecoration(
        color: YuniWidgetConfig.instance.colors.onBackground,
      ),
      pageController: notifier.pageController,
      onPageChanged: notifier.onPageChanged,
    );
  }

  Widget _buildOriginalToggle(
    PhotoPickerState pickerState,
    PhotoPickerNotifier pickerNotifier,
  ) {
    final config = YuniWidgetConfig.instance;
    final sizeText = _formatBytes(pickerState.totalSelectedSize);
    return YTapped(
      onTap: pickerNotifier.toggleSendOriginal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioIconWidget(selected: pickerState.sendOriginal, size: 20),
          YSpacing.widthSm(),
          YText(
            '原图',
            style: config.textStyles.bodyMediumBold.copyWith(
              color: config.colors.onInfo,
            ),
          ),
          if (pickerState.sendOriginal) ...[
            YSpacing.widthSm(),
            YText(
              sizeText,
              style: config.textStyles.bodySmallRegular.copyWith(
                color: config.colors.onInfo,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0B';
    const units = ['B', 'KB', 'MB', 'GB'];
    int i = 0;
    double value = bytes.toDouble();
    while (value >= 1024 && i < units.length - 1) {
      value /= 1024;
      i++;
    }
    return '${value.toStringAsFixed(value >= 100
        ? 0
        : value >= 10
        ? 1
        : 2)}${units[i]}';
  }

  /// 构建位置信息
  Widget _buildPositionInfo(PhotoViewerState state) {
    return AnimatedOpacity(
      opacity: state.isUIVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Center(
        child: YText(
          '${state.currentIndex + 1} / ${state.assets.length}',
          style: YuniWidgetConfig.instance.textStyles.bodyLargeBold.copyWith(
            color: YuniWidgetConfig.instance.colors.onPrimary,
          ),
        ),
      ),
    );
  }

  /// 构建手势检测层
  // Widget _buildGestureLayer(PhotoViewerNotifier notifier) {
  //   return Positioned.fill(
  //     child: GestureDetector(
  //       onTap: () {
  //         notifier.toggleUIVisibility();
  //       },
  //       behavior: HitTestBehavior.deferToChild,
  //       child: Container(),
  //     ),
  //   );
  // }
}
