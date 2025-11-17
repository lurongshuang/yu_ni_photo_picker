import 'dart:io';
import 'dart:typed_data';

import 'package:motion_photos/motion_photos.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:image_picker/image_picker.dart';

import '../config/picker_file.dart';

class PhotoPickerService {
  /// 构建过滤配置：按创建时间倒序，同时按需为图片/视频分别设置 FilterOption
  static FilterOptionGroup buildFilterOption({
    required List<AssetType> requestType,
    required OrderOptionType orderBy,
    required bool orderAsc,
  }) {
    final filter =
        FilterOptionGroup()
          ..addOrderOption(OrderOption(type: orderBy, asc: orderAsc));

    if (requestType.contains(AssetType.image)) {
      filter.setOption(AssetType.image, const FilterOption());
    }
    if (requestType.contains(AssetType.video)) {
      filter.setOption(AssetType.video, const FilterOption());
    }
    return filter;
  }

  /// 获取所有相册路径
  static Future<List<AssetPathEntity>> getAllAlbumPaths({
    required List<AssetType> requestType,
  }) async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (permission != PermissionState.limited &&
        permission != PermissionState.authorized) {
      return [];
    }

    final filterOption = buildFilterOption(
      requestType: requestType,
      orderBy: OrderOptionType.createDate,
      orderAsc: false,
    );

    final reqType =
        (requestType.contains(AssetType.image) &&
                requestType.contains(AssetType.video))
            ? RequestType.common
            : (requestType.contains(AssetType.video)
                ? RequestType.video
                : RequestType.image);

    final paths = await PhotoManager.getAssetPathList(
      type: reqType,
      filterOption: filterOption,
    );
    return paths;
  }

  /// 分页拉取：从指定路径按页获取资源
  static Future<List<AssetEntity>> loadAssetsPage({
    required AssetPathEntity path,
    required int page,
    required int size,
  }) async {
    return path.getAssetListPaged(page: page, size: size);
  }

  /// 获取路径下资源总数（用于判断还有没有更多）
  static Future<int> getAssetCount(AssetPathEntity path) {
    return path.assetCountAsync;
  }

  /// 将 AssetEntity 转为 XFile（原图/原视频）
  static Future<XFile?> toXFile(AssetEntity entity) async {
    final file = await entity.originFile.catchError((el) {
      return null;
    });
    if (file == null) return null;

    ///原文件名
    final originFileName = await entity.titleAsync;
    final mimeType = await entity.mimeTypeAsync;
    return XFile(file.path, name: originFileName, mimeType: mimeType);
  }

  static const String _outputDirectory = 'motion_photos';

  static Future<Directory> _createOutputDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final outputDir = Directory('${appDir.path}/$_outputDirectory');

    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }
    return outputDir;
  }

  /// 将 AssetEntity 转为 PhotoPickerFile（原图/原视频）
  static Future<PhotoPickerFile?> toPhotoPickerFile(AssetEntity entity) async {
    final file = await entity.originFile.catchError((el) {
      return null;
    });
    if (file == null) return null;
    String? mediaUrl;
    bool isLivePhoto = entity.isLivePhoto;

    ///原文件名
    final originFileName = await entity.titleAsync;
    final mimeType = await entity.mimeTypeAsync;

    if (Platform.isIOS) {
      if (isLivePhoto) {
        mediaUrl = await entity.getMediaUrl();
      }
    } else if (Platform.isAndroid && entity.type == AssetType.image) {
      final MotionPhotos motionPhotos = MotionPhotos(file.path);
      final isMotionPhoto = await motionPhotos.isMotionPhoto();
      isLivePhoto = isMotionPhoto;
      if (isLivePhoto) {
        final outputDir = await _createOutputDirectory();
        final motionVideoFile = await motionPhotos.getMotionVideoFile(
          outputDir,
          fileName: "${originFileName}_motion_photos",
        );
        if (motionVideoFile.existsSync()) {
          mediaUrl = motionVideoFile.path;
        } else {
          isLivePhoto = false;
        }
      }
    }

    return PhotoPickerFile(
      xFile: XFile(file.path, name: originFileName, mimeType: mimeType),
      isLivePhoto: isLivePhoto,
      mediaUrl: mediaUrl,
      fileName: originFileName,
    );
  }

  /// 缩略图缓存
  static final Map<String, Future<Uint8List?>> _thumbCache = {};

  /// 获取缩略图，带缓存
  static Future<Uint8List?> getThumbnail(
    AssetEntity asset,
    ThumbnailSize size, {
    int quality = 100,
  }) async {
    final cacheKey = "${asset.id}_${size.width}x${size.height}x$quality";

    if (!_thumbCache.containsKey(cacheKey)) {
      _thumbCache[cacheKey] = asset.thumbnailDataWithSize(
        size,
        quality: quality,
      );
    }

    return _thumbCache[cacheKey];
  }

  /// 清除缩略图缓存
  static void clearThumbnailCache() {
    _thumbCache.clear();
  }

  /// 预加载下一批缩略图
  static void preloadThumbnails(List<AssetEntity> assets, ThumbnailSize size) {
    for (final asset in assets) {
      getThumbnail(asset, size); // 触发缓存但不等待结果
    }
  }
}

