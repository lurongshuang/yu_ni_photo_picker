import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:yu_ni_photo_picker/src/constants/app_assets.dart';
import 'package:yu_ni_photo_picker/src/utils/asset_util.dart';
import '../components/live_photo_icon_widget.dart';
import '../model/photo_picker_state.dart';
import '../config/photo_picker_config.dart';
import '../service/photo_picker_service.dart'; // 添加这一行导入 PhotoPickerService
import '../providers/photo_picker_provider.dart';
import '../components/radio_icon_widget.dart';
import '../utils/date_time_formatter.dart';
import 'package:yuni_widget/yuni_widget.dart';

import '../constants/constants.dart';

class PhotoPickerItem extends ConsumerStatefulWidget {
  final ChoiceAssetEntity entity;
  final PhotoPickerConfig config;

  const PhotoPickerItem({
    super.key,
    required this.entity,
    required this.config,
  });

  @override
  ConsumerState<PhotoPickerItem> createState() => _PhotoPickerItemState();
}

class _PhotoPickerItemState extends ConsumerState<PhotoPickerItem> {
  late Future<Uint8List?> _thumbFuture;

  @override
  void initState() {
    super.initState();
    _thumbFuture = PhotoPickerService.getThumbnail(
      widget.entity.asset,
      defaultAssetGridPreviewSize,
    );
  }

  @override
  void didUpdateWidget(covariant PhotoPickerItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entity.asset.id != widget.entity.asset.id) {
      _thumbFuture = _loadThumb();
    }
  }

  Future<Uint8List?> _loadThumb() {
    return PhotoPickerService.getThumbnail(
      widget.entity.asset,
      defaultAssetGridPreviewSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = YuniWidgetConfig.instance;
    final notifier = ref.read(photoPickerProvider(widget.config).notifier);
    final status = ref.watch(photoPickerProvider(widget.config));
    return FutureBuilder<Uint8List?>(
      key: ValueKey(widget.entity.asset.id),
      future: _thumbFuture,
      builder: (_, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) {
          return Center(
            child: Container(
              decoration: BoxDecoration(color: config.colors.surface),
            ),
          );
        }
        final image = Container(
          color: config.colors.surface,
          child: Image.memory(bytes, fit: BoxFit.cover),
        );
        return GestureDetector(
          onTap: () {
            notifier.toggleSelect(widget.entity.asset);
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              image,
              Visibility(
                visible: widget.entity.isSelected,
                child: Container(
                  color: config.colors.onSurface.withValues(alpha: 0.5),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                child: YTapped(
                  onTap: () {
                    notifier.toggleSelect(widget.entity.asset);
                  },
                  child: YSpacing.all(
                    all: config.spacing.xs,
                    child: RadioIconWidget(
                      size: 20,
                      selected: widget.entity.isSelected,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                child: YTapped(
                  onTap: () {
                    notifier.toggleSelect(widget.entity.asset);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    color: Colors.transparent,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                child: Visibility(
                  visible:
                      widget.entity.asset.type == AssetType.video ||
                      widget.entity.asset.type == AssetType.audio,
                  child: YSpacing.all(
                    all: config.spacing.xs,
                    child: YText(
                      DateTimeFormatter.formatTimestamp(
                        widget.entity.asset.duration * 1000,
                        format: "mm:ss",
                      ),
                      style: config.textStyles.labelLargeRegular.copyWith(
                        color: config.colors.surface,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                child: FutureBuilder(
                  future: isMotionPhotos(),
                  builder: (context, value) {
                    return Visibility(
                      visible: value.data ?? false,
                      child: YSpacing.all(
                        all: config.spacing.xs,
                        child: LivePhotoIconWidget(
                          size: 24,
                          isOpen:
                              status.liveVideoUploadMap[widget
                                  .entity
                                  .asset
                                  .id] ??
                              true,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                child: YTapped(
                  onTap: () {
                    notifier.toggleLiveVideo(widget.entity.asset);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    color: Colors.transparent,
                  ),
                ),
              ),

              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  margin: EdgeInsets.all(config.spacing.xxs),
                  decoration: BoxDecoration(
                    color: config.colors.onBackground.withValues(alpha: 0.5),
                    borderRadius: config.radius.borderSm,
                  ),
                  child: AssetUtil.loadAssetsImage(
                    AppAssets.images.zoomIcon,
                    width: 21,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: YTapped(
                  onTap: () {
                    notifier.jumpToViewer(context, widget.entity.asset);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    color: Colors.transparent,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> isMotionPhotos() async {
    if (Platform.isIOS) {
      return widget.entity.asset.isLivePhoto;
    }
    return false;
    // if (widget.entity.asset.type != AssetType.image) {
    //   return false;
    // }
    // final file = await widget.entity.asset.originFile;
    // if (file == null) {
    //   return false;
    // }
    // try {
    //   if (!await file.exists()) {
    //     return false;
    //   }
    //   final MotionPhotos motionPhotos = MotionPhotos(file.path);
    //   return motionPhotos.isMotionPhoto();
    // } catch (e) {
    //   return false;
    // }
  }
}
