import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_view/photo_view.dart';
import '../components/live_photo_icon_widget.dart';
import '../service/photo_picker_service.dart';
import 'package:yuni_widget/yuni_widget.dart';

/// 图片查看器组件
class PhotoViewerImageWidget extends StatefulWidget {
  final AssetEntity asset;
  final PhotoViewScaleStateController? scaleStateController;
  final PhotoViewImageScaleEndCallback? onScaleStateChanged;

  // final VoidCallback? onTap;

  const PhotoViewerImageWidget({
    super.key,
    required this.asset,
    this.scaleStateController,
    this.onScaleStateChanged,
    // this.onTap,
  });

  @override
  State<PhotoViewerImageWidget> createState() => _PhotoViewerImageWidgetState();
}

class _PhotoViewerImageWidgetState extends State<PhotoViewerImageWidget> {
  late Future<Uint8List?> _thumbFuture;

  @override
  void initState() {
    super.initState();
    _thumbFuture = PhotoPickerService.getThumbnail(
      widget.asset,
      ThumbnailSize(800, 600),
    );
  }

  @override
  void didUpdateWidget(covariant PhotoViewerImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset.id != widget.asset.id) {
      _thumbFuture = _loadThumb();
    }
  }

  Future<Uint8List?> _loadThumb() {
    return PhotoPickerService.getThumbnail(
      widget.asset,
      ThumbnailSize(800, 600),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = YuniWidgetConfig.instance;
    return FutureBuilder<Uint8List?>(
      key: ValueKey(widget.asset.id),
      future: _thumbFuture,
      builder: (_, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) {
          return Center(
            child: Container(decoration: BoxDecoration(color: Colors.black)),
          );
        }
        final image = Container(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(bytes),
              Positioned(
                left: config.spacing.md,
                top: config.spacing.md,
                child: Visibility(
                  visible: widget.asset.isLivePhoto,
                  child: SafeArea(child: LivePhotoWidget()),
                ),
              ),
            ],
          ),
        );
        return Stack(fit: StackFit.expand, children: [image]);
      },
    );
    // return PhotoView(
    //   imageProvider: CachedAssetEntityImageProvider(asset, isOriginal: false),
    //   // scaleStateController: scaleStateController,
    //   // onScaleEnd: onScaleStateChanged,
    //   // onTapUp:
    //   //     onTap != null
    //   //         ? (context, details, controllerValue) => onTap!()
    //   //         : null,
    //   minScale: PhotoViewComputedScale.contained,
    //   maxScale: PhotoViewComputedScale.covered * 4.0,
    //   initialScale: PhotoViewComputedScale.contained,
    //   loadingBuilder: (context, event) {
    //     return Center(child: YLoading.circular());
    //   },
    //   errorBuilder: (context, error, stackTrace) {
    //     return const ImageError();
    //   },
    // );
  }
}

/// 带缓存的AssetEntity图片提供者
// class CachedAssetEntityImageProvider
//     extends ImageProvider<CachedAssetEntityImageProvider> {
//   final AssetEntity asset;
//   final bool isOriginal;
//
//   const CachedAssetEntityImageProvider(this.asset, {this.isOriginal = false});
//
//   @override
//   Future<CachedAssetEntityImageProvider> obtainKey(
//     ImageConfiguration configuration,
//   ) {
//     return SynchronousFuture<CachedAssetEntityImageProvider>(this);
//   }
//
//   @override
//   ImageStreamCompleter loadImage(
//     CachedAssetEntityImageProvider key,
//     ImageDecoderCallback decode,
//   ) {
//     return MultiFrameImageStreamCompleter(
//       codec: _loadAsync(key, decode),
//       scale: 1.0,
//     );
//   }
//
//   Future<ui.Codec> _loadAsync(
//     CachedAssetEntityImageProvider key,
//     ImageDecoderCallback decode,
//   ) async {
//     assert(key == this);
//
//     Uint8List? bytes;
//
//     if (isOriginal) {
//       // 原图直接从asset获取
//       bytes = await asset.originBytes;
//     } else {
//       // 缩略图使用缓存服务
//       final thumbnailSize = ThumbnailSize(800, 600);
//       bytes = await PhotoPickerService.getThumbnail(asset, thumbnailSize);
//     }
//
//     if (bytes == null || bytes.isEmpty) {
//       throw StateError('Unable to read data from asset: ${asset.id}');
//     }
//
//     final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
//     return decode(buffer);
//   }
//
//   @override
//   bool operator ==(Object other) {
//     if (other.runtimeType != runtimeType) return false;
//     return other is CachedAssetEntityImageProvider &&
//         other.asset.id == asset.id &&
//         other.isOriginal == isOriginal;
//   }
//
//   @override
//   int get hashCode => Object.hash(asset.id, isOriginal);
//
//   @override
//   String toString() =>
//       'CachedAssetEntityImageProvider("${asset.id}", scale: ${isOriginal ? 'original' : 'thumbnail'})';
// }

/// 自定义的AssetEntity图片提供者（保留原版本以备兼容）
class AssetEntityImageProvider extends ImageProvider<AssetEntityImageProvider> {
  final AssetEntity asset;
  final bool isOriginal;

  const AssetEntityImageProvider(this.asset, {this.isOriginal = false});

  @override
  Future<AssetEntityImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<AssetEntityImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    AssetEntityImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: 1.0,
    );
  }

  Future<ui.Codec> _loadAsync(
    AssetEntityImageProvider key,
    ImageDecoderCallback decode,
  ) async {
    assert(key == this);

    final Uint8List? bytes = await asset.originBytes;
    if (bytes == null || bytes.isEmpty) {
      throw StateError('Unable to read data from asset: ${asset.id}');
    }

    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    return decode(buffer);
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is AssetEntityImageProvider &&
        other.asset.id == asset.id &&
        other.isOriginal == isOriginal;
  }

  @override
  int get hashCode => Object.hash(asset.id, isOriginal);

  @override
  String toString() =>
      'AssetEntityImageProvider("${asset.id}", scale: ${isOriginal ? 'original' : 'thumbnail'})';
}

