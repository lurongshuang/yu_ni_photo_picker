import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../service/photo_picker_service.dart';
import '../components/radio_icon_widget.dart';
import '../constants/app_assets.dart';
import '../utils/asset_util.dart';
import 'package:yuni_widget/yuni_widget.dart';

import '../constants/constants.dart';

///切换相册
class AlbumSelectorBottomSheet extends StatefulWidget {
  final List<AssetPathEntity> albums;
  final AssetPathEntity? currentAlbum;
  final Function(AssetPathEntity) onAlbumSelected;

  const AlbumSelectorBottomSheet({
    super.key,
    required this.albums,
    required this.currentAlbum,
    required this.onAlbumSelected,
  });

  @override
  State<AlbumSelectorBottomSheet> createState() =>
      _AlbumSelectorBottomSheetState();
}

class _AlbumSelectorBottomSheetState extends State<AlbumSelectorBottomSheet> {
  final ScrollController itemScrollController = ScrollController();

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((d) {
      int index = 0;
      if (widget.currentAlbum != null) {
        index = widget.albums.indexWhere(
          (el) => el.id == widget.currentAlbum?.id,
        );
        if (index < 0) {
          index = 0;
        }
      }
      double itemHeight = 60 + 16;
      itemScrollController.animateTo(
        index * itemHeight,
        duration: Duration(milliseconds: 100),
        curve: Curves.linear,
      );
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final config = YuniWidgetConfig.instance;

    return Column(
      children: [
        YTapped(
          onTap: () {
            Navigator.pop(context);
          },
          child: Container(
            width: double.infinity,
            height: 100,
            color: Colors.transparent,
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: config.colors.surface,
              borderRadius: BorderRadius.vertical(top: config.radius.radiusXl),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 30,
                  height: 5.0,
                  margin: EdgeInsets.only(top: config.spacing.sm),
                  decoration: BoxDecoration(
                    color: config.colors.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(config.radius.full),
                  ),
                ),
                YTapped(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: config.spacing.lg,
                    ),
                    child: Row(
                      children: [
                        AssetUtil.loadAssetsImage(
                          AppAssets.images.leadingIcon,
                          width: 14,
                        ),
                        YSpacing.widthSm(),
                        YText.bodyLargeBold('相册'),
                      ],
                    ),
                  ),
                ),
                YSpacing.heightSm(),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: widget.albums.length,
                    controller: itemScrollController,
                    itemBuilder: (context, index) {
                      final album = widget.albums[index];
                      final isSelected = widget.currentAlbum?.id == album.id;
                      final config = YuniWidgetConfig.instance;
                      return YTapped(
                        onTap: () {
                          widget.onAlbumSelected(album);
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: config.spacing.lg,
                            vertical: config.spacing.sm,
                          ),
                          color: Colors.transparent,
                          child: Row(
                            children: [
                              FutureBuilder<AssetEntity?>(
                                future: _getFirstAsset(album),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData &&
                                      snapshot.data != null) {
                                    return FutureBuilder<Uint8List?>(
                                      future: PhotoPickerService.getThumbnail(
                                        snapshot.data!,
                                        defaultPathThumbnailSize,
                                      ),
                                      builder: (context, thumbSnapshot) {
                                        if (thumbSnapshot.hasData &&
                                            thumbSnapshot.data != null) {
                                          return Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  config.radius.borderMd,
                                              image: DecorationImage(
                                                image: MemoryImage(
                                                  thumbSnapshot.data!,
                                                ),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          );
                                        }
                                        return _buildPlaceholder();
                                      },
                                    );
                                  }
                                  return _buildPlaceholder();
                                },
                              ),
                              YSpacing.widthMd(),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    YText(
                                      album.name,
                                      style: config.textStyles.bodyMediumBold,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    YSpacing.heightXs(),
                                    FutureBuilder<int>(
                                      future: album.assetCountAsync,
                                      builder: (context, countSnapshot) {
                                        final count = countSnapshot.data ?? 0;
                                        return YText(
                                          '$count 项',
                                          style: config
                                              .textStyles
                                              .bodySmallRegular
                                              .copyWith(
                                                color: config.colors.onSurface
                                                    .withValues(alpha: 0.6),
                                              ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              isSelected
                                  ? RadioIconWidget(selected: true, size: 20)
                                  : AssetUtil.loadAssetsImage(
                                    AppAssets.images.rightArrowIcon,
                                    width: 24,
                                  ),
                            ],
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) {
                      return YSpacing.only(
                        child: YDivider(),
                        left: 60 + config.spacing.lg + config.spacing.md,
                      );
                    },
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    final config = YuniWidgetConfig.instance;
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: config.colors.onSurface.withValues(alpha: 0.1),
        borderRadius: config.radius.borderMd,
      ),
      child: AssetUtil.loadAssetsImage(
        AppAssets.images.tabPhotoIcon,
        color: config.colors.onSurface.withValues(alpha: 0.3),
        width: 24,
      ),
    );
  }

  Future<AssetEntity?> _getFirstAsset(AssetPathEntity album) async {
    final assets = await album.getAssetListPaged(page: 0, size: 1);
    return assets.isNotEmpty ? assets.first : null;
  }
}
