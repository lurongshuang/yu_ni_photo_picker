/// 相册文件列表布局格式
enum AlbumLayoutFormat {
  listView, // 列表视图
  gridView, // 宫格视图
  fileView, // 文件视图
}

/// 列表数据排序方式
enum AlbumSortType {
  shootTime, // 按拍摄时间排序
  uploadTime, // 按上传时间排序
  name, // 按名称排序
}

/// 相册设置类（简化版本，不依赖AppConfigBase）
class AlbumSettings {
  final Map<String, dynamic> cache;
  final dynamic prefs; // SharedPreferences or similar

  AlbumSettings({required this.cache, required this.prefs});

  final String _layoutFormatKey = 'album_layout_format_key';
  final String _sortTypeKey = 'album_sort_type_key';
  final String _groupByDateKey = 'album_group_by_date_key';

  /// 获取相册文件列表布局格式
  AlbumLayoutFormat get layoutFormat {
    final value = cache[_layoutFormatKey];
    if (value == null) return AlbumLayoutFormat.gridView; // 默认宫格视图

    switch (value) {
      case 'listView':
        return AlbumLayoutFormat.listView;
      case 'gridView':
        return AlbumLayoutFormat.gridView;
      case 'fileView':
        return AlbumLayoutFormat.fileView;
      default:
        return AlbumLayoutFormat.gridView;
    }
  }

  /// 获取列表数据排序方式
  AlbumSortType get sortType {
    final value = cache[_sortTypeKey];
    if (value == null) return AlbumSortType.uploadTime; // 默认按上传时间排序

    switch (value) {
      case 'shootTime':
        return AlbumSortType.shootTime;
      case 'uploadTime':
        return AlbumSortType.uploadTime;
      case 'name':
        return AlbumSortType.name;
      default:
        return AlbumSortType.uploadTime;
    }
  }

  /// 获取是否按照日期分组
  bool get isGroupByDate => cache[_groupByDateKey] ?? true; // 默认开启日期分组

  /// 设置相册文件列表布局格式
  Future<bool> setLayoutFormat(AlbumLayoutFormat format) async {
    final formatString = format.name;
    if (cache[_layoutFormatKey] == formatString) {
      return true;
    }
    cache[_layoutFormatKey] = formatString;
    return prefs.setString(_layoutFormatKey, formatString);
  }

  /// 设置列表数据排序方式
  Future<bool> setSortType(AlbumSortType sortType) async {
    final sortTypeString = sortType.name;
    if (cache[_sortTypeKey] == sortTypeString) {
      return true;
    }
    cache[_sortTypeKey] = sortTypeString;
    return prefs.setString(_sortTypeKey, sortTypeString);
  }

  /// 设置是否按照日期分组
  Future<bool> setGroupByDate(bool groupByDate) async {
    if (groupByDate == cache[_groupByDateKey]) {
      return true;
    }
    cache[_groupByDateKey] = groupByDate;
    return prefs.setBool(_groupByDateKey, groupByDate);
  }

  void dispose() {
    cache.clear();
  }
}
