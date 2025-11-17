import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yu_ni_photo_picker/src/components/status_empty_widget.dart';
import '../components/app_bar/photos_app_bar.dart';
import '../model/photo_picker_state.dart';
import '../config/photo_picker_config.dart';
import '../providers/photo_picker_provider.dart';
import '../widget/album_selector_bottom_sheet.dart';
import '../components/drag_selectable_grid_view.dart';
import '../components/date_grouped_grid_view.dart';
import '../components/status_widget.dart';
import '../config/album_settings.dart';
import '../constants/app_assets.dart';
import '../utils/asset_util.dart';
import '../utils/device_type_util.dart';
import 'package:yuni_widget/yuni_widget.dart';
import '../components/radio_icon_widget.dart';
import '../widget/rectangular_indicator.dart';

class PhotoPickerPage extends ConsumerStatefulWidget {
  final PhotoPickerConfig config;

  const PhotoPickerPage({super.key, required this.config});

  @override
  ConsumerState<PhotoPickerPage> createState() => _PhotoPickerPageState();
}

class _PhotoPickerPageState extends ConsumerState<PhotoPickerPage>
    with TickerProviderStateMixin {
  bool _isAlbumSheetOpen = false;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((d) async {
      // 初始化设备类型（必须在初始化照片选择器之前）
      if (!DeviceTypeUtil.instance.isInitialized) {
        await DeviceTypeUtil.instance.initDeviceType(context);
      }
      if (!mounted) {
        return;
      }
      // 初始化照片选择器
      ref
          .read(photoPickerProvider(widget.config).notifier)
          .initialization(context);
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(photoPickerProvider(widget.config));
    final notifier = ref.read(photoPickerProvider(widget.config).notifier);
    final config = YuniWidgetConfig.instance;
    final selectedIndex =
        {
          AssetCategory.all: 0,
          AssetCategory.video: 1,
          AssetCategory.image: 2,
          AssetCategory.live: 3,
        }[status.currentCategory] ??
        0;
    if (_tabController.index != selectedIndex) {
      _tabController.index = selectedIndex;
    }
    return Scaffold(
      appBar: PhotosAppBar(
        bgColor: Colors.transparent,
        customTitleWidget: YTapped(
          onTap: () => _showAlbumSelector(context, status, notifier),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: YText(
                  status.currentAlbum?.name ?? '相册',
                  style: YuniWidgetConfig.instance.textStyles.bodyLargeBold
                      .copyWith(height: 1),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AnimatedRotation(
                turns: _isAlbumSheetOpen ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: AssetUtil.loadAssetsImage(
                  AppAssets.images.arrowIcon,
                  width: 24,
                  height: 24,
                  color: YuniWidgetConfig.instance.colors.onSurface,
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (widget.config.allowMultiple) // 只在多选模式下显示全选按钮
            YTapped(
              onTap: () {
                notifier.switchCheckAll();
              },
              child: YText(
                status.allSelected ? "取消全选" : "全选",
                style: config.textStyles.bodyMediumBold.copyWith(
                  color: config.colors.primary,
                ),
              ),
            ),
          YSpacing.widthLg(),
        ],
      ),
      body: Stack(
        children: [
          _buildBody(status, notifier),
          if (status.selectedCount > 0)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16 + MediaQuery.of(context).padding.bottom,
              child: _buildBottomBar(status, notifier),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(
    PhotoPickerState status,
    PhotoPickerNotifier notifier,
  ) {
    final config = YuniWidgetConfig.instance;
    final sizeText = _formatBytes(status.totalSelectedSize);
    final children = <Widget>[];
    if (widget.config.showPreviewButton) {
      children.add(
        Align(
          alignment: Alignment.centerLeft,
          child: YTapped(
            onTap: () => notifier.previewSelected(context),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: config.spacing.md,
                vertical: config.spacing.xs,
              ),
              decoration: BoxDecoration(
                color: config.colors.surface,
                borderRadius: config.radius.borderFull,
                boxShadow: [
                  BoxShadow(
                    color: config.colors.onSurface.withValues(alpha: 0.06),
                    blurRadius: config.spacing.lg,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: config.spacing.sm),
                child: YText('预览', style: config.textStyles.bodyMediumBold),
              ),
            ),
          ),
        ),
      );
    }
    if (widget.config.showOriginalToggle) {
      children.add(
        Center(
          child: YTapped(
            onTap: notifier.toggleSendOriginal,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: config.spacing.md,
                vertical: config.spacing.xs,
              ),
              decoration: BoxDecoration(
                color: config.colors.surface,
                borderRadius: config.radius.borderFull,
                boxShadow: [
                  BoxShadow(
                    color: config.colors.onSurface.withValues(alpha: 0.06),
                    blurRadius: config.spacing.lg,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioIconWidget(
                    selected: status.sendOriginal,
                    size: 20,
                    isTransparentUnSelect: true,
                  ),
                  YSpacing.widthSm(),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: config.spacing.sm),
                    child: YText(
                      '原图',
                      style: config.textStyles.bodyMediumBold.copyWith(
                        height: 1,
                      ),
                    ),
                  ),
                  if (status.sendOriginal) ...[
                    YSpacing.widthSm(),
                    YText(
                      sizeText,
                      style: config.textStyles.bodySmallRegular.copyWith(
                        color: config.colors.onSurface,
                        height: 1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }
    children.add(
      Align(
        alignment: Alignment.centerRight,
        child: YTapped(
          onTap: () => notifier.confirm(context),
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
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                YText(
                  widget.config.confirmButtonText,
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
                      '${status.selectedCount}',
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
        ),
      ),
    );
    return Stack(children: children);
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

  void _showAlbumSelector(
    BuildContext context,
    PhotoPickerState status,
    PhotoPickerNotifier notifier,
  ) {
    if (status.albumPaths.isEmpty) return;
    setState(() {
      _isAlbumSheetOpen = true;
    });
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => AlbumSelectorBottomSheet(
            albums: status.albumPaths,
            currentAlbum: status.currentAlbum,
            onAlbumSelected: (album) {
              notifier.switchAlbum(album);
            },
          ),
    ).whenComplete(() {
      if (!mounted) return;
      setState(() {
        _isAlbumSheetOpen = false;
      });
    });
  }

  Widget _buildBody(PhotoPickerState status, PhotoPickerNotifier notifier) {
    final itemCount = status.assets.length;
    final hasMore = status.hasMore;
    final isLoadingMore = status.isLoadingMore;
    // final totalTiles = itemCount + ((hasMore || isLoadingMore) ? 1 : 0);
    final crossAxisCount = DeviceTypeUtil.instance.isMobile ? 3 : 8;
    final config = YuniWidgetConfig.instance;
    return StatusWidget(
      state: status.status,
      child: Column(
        children: [
          if (widget.config.enableCategoryTabs)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: config.spacing.sm,
                vertical: config.spacing.md,
              ),
              child: _buildCategoryTabs(status, notifier),
            ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child:
                  status.assets.isEmpty
                      ? const StatusEmptyWidget()
                      : Padding(
                        key: ValueKey(status.currentCategory),
                        padding: EdgeInsets.symmetric(
                          horizontal: config.spacing.sm,
                        ),
                        child: DateGroupedGridView(
                          assets: status.assets,
                          groupByDate: widget.config.groupByDate,
                          groupByMonth: widget.config.groupByMonth,
                          sortType: AlbumSortType.shootTime,
                          crossAxisCount: crossAxisCount,
                          padding: EdgeInsets.all(config.spacing.sm),
                          controller: notifier.scrollController,
                          enableDragSelection: widget.config.allowMultiple,
                          selectionController: notifier.selectionController,
                          selectionMode:
                              widget.config.allowMultiple
                                  ? SelectionMode.multiple
                                  : SelectionMode.single,
                          maxSelection: widget.config.maxAssets,
                          hasMore: hasMore,
                          isLoadingMore: isLoadingMore,
                          config: widget.config,
                          onSelectionChanged: (indices) {
                            notifier.selectionController.setSelection(indices);
                          },
                          onItemTap: (index) {
                            if (index < itemCount) {
                              final asset = status.assets[index].asset;
                              if (widget.config.allowMultiple) {
                                notifier.toggleSelect(asset);
                              } else {
                                notifier.jumpToViewer(context, asset);
                              }
                            }
                          },
                          onItemLongPress: (index) {
                            if (index < itemCount &&
                                widget.config.allowMultiple) {
                              notifier.startDragSelection(index);
                            }
                          },
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(
    PhotoPickerState status,
    PhotoPickerNotifier notifier,
  ) {
    final tabs = const [
      Tab(text: '全部'),
      Tab(text: '视频'),
      Tab(text: '照片'),
      Tab(text: '实况图'),
    ];
    return AlbumTypeTabBarWidget(
      tabController: _tabController,
      tabViews: tabs,
      height: 48,
    );
  }

  void _handleTabChanged() {
    if (!_tabController.indexIsChanging) {
      final map = [
        AssetCategory.all,
        AssetCategory.video,
        AssetCategory.image,
        AssetCategory.live,
      ];
      final notifier = ref.read(photoPickerProvider(widget.config).notifier);
      notifier.setCategory(map[_tabController.index]);
    }
  }
}

class AlbumTypeTabBarWidget extends StatelessWidget {
  final TabController tabController;
  final List<Widget> tabViews;
  final double height;

  const AlbumTypeTabBarWidget({
    super.key,
    required this.tabController,
    required this.tabViews,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final config = YuniWidgetConfig.instance;
    return Container(
      decoration: BoxDecoration(
        color: config.colors.surface,
        borderRadius: config.radius.borderLg,
      ),
      padding: EdgeInsets.all(config.spacing.xs),
      height: height,
      child: TabBar(
        controller: tabController,
        padding: EdgeInsets.zero,
        tabs: tabViews,
        labelColor: config.colors.onSurface,
        unselectedLabelColor: config.colors.withAlpha(
          config.colors.onBackground,
          0.6,
        ),
        labelPadding: EdgeInsets.zero,
        unselectedLabelStyle: config.textStyles.labelLargeRegular,
        labelStyle: config.textStyles.labelLargeRegular.copyWith(
          color: config.colors.onBackground,
        ),
        indicator: RectangularIndicator(
          topLeftRadius: config.radius.lg - 2,
          topRightRadius: config.radius.lg - 2,
          bottomLeftRadius: config.radius.lg - 2,
          bottomRightRadius: config.radius.lg - 2,
          color: config.colors.background,
          paintingStyle: PaintingStyle.fill,
        ),
      ),
    );
  }
}
