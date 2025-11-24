import 'package:photo_manager/photo_manager.dart';
import '../utils/base_state.dart';
import '../utils/page_status.dart';

enum AssetCategory {
  all,
  image,
  video,
  live,
}

class ChoiceAssetEntity {
  final AssetEntity asset;
  bool isSelected;

  ChoiceAssetEntity({required this.asset, this.isSelected = false});
}

class PhotoPickerState extends BaseState<PhotoPickerState> {
  final List<ChoiceAssetEntity> allAssets;
  final List<ChoiceAssetEntity> assets;
  final AssetPathEntity? recentPath;
  final List<AssetPathEntity> albumPaths;
  final AssetPathEntity? currentAlbum;
  final int page;
  final int totalCount;
  final bool hasMore;
  final bool isLoadingMore;
  final int selectedCount;
  final List<AssetEntity> globalSelectedAssets;
  final bool allSelected;
  // 滑动选择相关状态
  final bool isDragSelecting;
  final bool? dragStartSelectState;
  final int lastDragIndex;
  final bool sendOriginal;
  final int totalSelectedSize;
  final AssetCategory currentCategory;
  final Map<String, bool> liveVideoUploadMap;

  const PhotoPickerState({
    this.allAssets = const [],
    this.assets = const [],
    this.recentPath,
    this.albumPaths = const [],
    this.currentAlbum,
    this.page = 0,
    this.totalCount = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
    super.status = PageStatus.initial,
    super.errorMessage,
    this.selectedCount = 0,
    this.globalSelectedAssets = const [],
    this.allSelected = false,
    // 滑动选择相关状态
    this.isDragSelecting = false,
    this.dragStartSelectState,
    this.lastDragIndex = -1,
    this.sendOriginal = false,
    this.totalSelectedSize = 0,
    this.currentCategory = AssetCategory.all,
    this.liveVideoUploadMap = const {},
  });

  @override
  PhotoPickerState copyWith({
    List<ChoiceAssetEntity>? allAssets,
    List<ChoiceAssetEntity>? assets,
    AssetPathEntity? recentPath,
    List<AssetPathEntity>? albumPaths,
    AssetPathEntity? currentAlbum,
    int? page,
    int? totalCount,
    bool? hasMore,
    bool? isLoadingMore,
    PageStatus? status,
    String? errorMessage,
    int? selectedCount,
    List<AssetEntity>? globalSelectedAssets,
    bool? allSelected,
    // 滑动选择相关参数
    bool? isDragSelecting,
    bool? dragStartSelectState,
    int? lastDragIndex,
    bool? sendOriginal,
    int? totalSelectedSize,
    AssetCategory? currentCategory,
    Map<String, bool>? liveVideoUploadMap,
  }) {
    return PhotoPickerState(
      allAssets: allAssets ?? this.allAssets,
      assets: assets ?? this.assets,
      recentPath: recentPath ?? this.recentPath,
      albumPaths: albumPaths ?? this.albumPaths,
      currentAlbum: currentAlbum ?? this.currentAlbum,
      page: page ?? this.page,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedCount: selectedCount ?? this.selectedCount,
      globalSelectedAssets: globalSelectedAssets ?? this.globalSelectedAssets,
      allSelected: allSelected ?? this.allSelected,
      // 滑动选择相关状态
       isDragSelecting: isDragSelecting ?? this.isDragSelecting,
       dragStartSelectState: dragStartSelectState ?? this.dragStartSelectState,
       lastDragIndex: lastDragIndex ?? this.lastDragIndex,
       sendOriginal: sendOriginal ?? this.sendOriginal,
       totalSelectedSize: totalSelectedSize ?? this.totalSelectedSize,
       currentCategory: currentCategory ?? this.currentCategory,
       liveVideoUploadMap: liveVideoUploadMap ?? this.liveVideoUploadMap,
     );
   }

   List<AssetEntity> get selected =>
      assets
          .where((item) => item.isSelected)
          .map((item) => item.asset)
          .toList();
}

