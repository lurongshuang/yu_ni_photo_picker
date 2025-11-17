import 'package:photo_manager/photo_manager.dart';
import '../utils/base_state.dart';
import '../utils/page_status.dart';
import 'photo_picker_state.dart';

/// 图片查看器状态类
class PhotoViewerState extends BaseState<PhotoViewerState> {
  /// 当前显示的图片列表
  final List<ChoiceAssetEntity> assets;
  
  /// 当前显示的图片索引
  final int currentIndex;
  
  /// 是否显示选择模式
  final bool isSelectionMode;
  
  /// 选中的图片列表
  final Set<int> selectedIndices;
  
  /// 是否显示UI控件（AppBar等）
  final bool isUIVisible;
  
  /// 是否正在加载
  final bool isLoading;
  
  /// 缩放比例
  final double scale;
  
  /// 是否可以左右滑动
  final bool canSwipe;
  
  /// 页面控制器的页面索引（用于PageView）
  final int pageIndex;

  /// 全局选中数量（所有相册的总选中数量）
  final int globalSelectedCount;

  const PhotoViewerState({
    this.assets = const [],
    this.currentIndex = 0,
    this.isSelectionMode = false,
    this.selectedIndices = const {},
    this.isUIVisible = true,
    this.isLoading = false,
    this.scale = 1.0,
    this.canSwipe = true,
    this.pageIndex = 0,
    this.globalSelectedCount = 0,
    super.status = PageStatus.initial,
    super.errorMessage,
  });

  @override
  PhotoViewerState copyWith({
    List<ChoiceAssetEntity>? assets,
    int? currentIndex,
    bool? isSelectionMode,
    Set<int>? selectedIndices,
    bool? isUIVisible,
    bool? isLoading,
    double? scale,
    bool? canSwipe,
    int? pageIndex,
    int? globalSelectedCount,
    PageStatus? status,
    String? errorMessage,
  }) {
    return PhotoViewerState(
      assets: assets ?? this.assets,
      currentIndex: currentIndex ?? this.currentIndex,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      selectedIndices: selectedIndices ?? this.selectedIndices,
      isUIVisible: isUIVisible ?? this.isUIVisible,
      isLoading: isLoading ?? this.isLoading,
      scale: scale ?? this.scale,
      canSwipe: canSwipe ?? this.canSwipe,
      pageIndex: pageIndex ?? this.pageIndex,
      globalSelectedCount: globalSelectedCount ?? this.globalSelectedCount,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// 获取当前图片
  AssetEntity? get currentAsset {
    if (currentIndex >= 0 && currentIndex < assets.length) {
      return assets[currentIndex].asset;
    }
    return null;
  }

  /// 获取选中的图片列表
  List<AssetEntity> get selectedAssets {
    return selectedIndices
        .where((index) => index >= 0 && index < assets.length)
        .map((index) => assets[index].asset)
        .toList();
  }

  /// 检查指定索引是否被选中
  bool isSelected(int index) {
    return selectedIndices.contains(index);
  }

  /// 检查当前图片是否被选中
  bool get isCurrentSelected {
    return isSelected(currentIndex);
  }

  /// 获取选中数量（当前相册的选中数量）
  int get selectedCount {
    return selectedIndices.length;
  }

  /// 获取全局选中数量（所有相册的总选中数量）
  int get totalSelectedCount {
    return globalSelectedCount;
  }

  /// 是否有上一张图片
  bool get hasPrevious {
    return currentIndex > 0;
  }

  /// 是否有下一张图片
  bool get hasNext {
    return currentIndex < assets.length - 1;
  }

  /// 获取当前图片的位置信息
  String get positionInfo {
    if (assets.isEmpty) return '0/0';
    return '${currentIndex + 1}/${assets.length}';
  }
}
