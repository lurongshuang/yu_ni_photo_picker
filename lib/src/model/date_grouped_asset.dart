import 'package:photo_manager/photo_manager.dart';
import '../config/album_settings.dart';
import 'photo_picker_state.dart';

/// 日期分组的数据项
class DateGroupedAsset {
  /// 日期字符串（格式：yyyy-MM-dd）
  final String dateKey;
  
  /// 该日期下的资源列表
  final List<ChoiceAssetEntity> assets;
  
  /// 日期显示文本（格式：yyyy年M月d日）
  final String dateLabel;

  DateGroupedAsset({
    required this.dateKey,
    required this.assets,
    required this.dateLabel,
  });
}

/// 日期分组工具类
class DateGroupUtil {
  /// 将资源列表按日期分组
  /// 
  /// [assets] 资源列表
  /// [sortType] 排序方式
  /// [groupByDate] 是否按日期分组
  /// [groupByMonth] 是否按月份分组（否则按天分组）
  static List<DateGroupedAsset> groupAssetsByDate({
    required List<ChoiceAssetEntity> assets,
    required AlbumSortType sortType,
    required bool groupByDate,
    bool groupByMonth = false,
  }) {
    if (!groupByDate || assets.isEmpty) {
      // 如果不分组，返回一个包含所有资源的组
      return [
        DateGroupedAsset(
          dateKey: '',
          assets: assets,
          dateLabel: '',
        ),
      ];
    }

    // 按日期分组
    final Map<String, List<ChoiceAssetEntity>> groupedMap = {};
    
    for (final asset in assets) {
      final dateKey = groupByMonth
          ? _getMonthKey(asset.asset, sortType)
          : _getDateKey(asset.asset, sortType);
      groupedMap.putIfAbsent(dateKey, () => []).add(asset);
    }

    // 转换为列表并排序
    final groupedList = groupedMap.entries.map((entry) {
      return DateGroupedAsset(
        dateKey: entry.key,
        assets: entry.value,
        dateLabel: groupByMonth
            ? _formatMonthLabel(entry.key)
            : _formatDateLabel(entry.key),
      );
    }).toList();

    // 按日期倒序排序（最新的在前）
    groupedList.sort((a, b) => b.dateKey.compareTo(a.dateKey));

    return groupedList;
  }

  /// 获取资源的日期键（yyyy-MM-dd格式）
  static String _getDateKey(AssetEntity asset, AlbumSortType sortType) {
    DateTime dateTime;
    
    switch (sortType) {
      case AlbumSortType.shootTime:
        dateTime = asset.createDateTime;
        break;
      case AlbumSortType.uploadTime:
        dateTime = asset.modifiedDateTime;
        break;
      case AlbumSortType.name:
        dateTime = asset.createDateTime;
        break;
    }

    // 格式化为 yyyy-MM-dd
    final year = dateTime.year.toString().padLeft(4, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// 格式化日期标签（yyyy年M月d日）
  static String _formatDateLabel(String dateKey) {
    if (dateKey.isEmpty) return '';
    
    try {
      final parts = dateKey.split('-');
      if (parts.length != 3) return dateKey;
      
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      
      return '$year年$month月$day日';
    } catch (e) {
      return dateKey;
    }
  }

  /// 获取相对日期标签（今天、昨天、X天前等）
  static String getRelativeDateLabel(String dateKey) {
    if (dateKey.isEmpty) return '';
    
    try {
      final parts = dateKey.split('-');
      if (parts.length != 3) return _formatDateLabel(dateKey);
      
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      
      final date = DateTime(year, month, day);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      
      if (date == today) {
        return '今天';
      } else if (date == yesterday) {
        return '昨天';
      } else {
        final diff = today.difference(date).inDays;
        if (diff < 7) {
          return '$diff天前';
        } else if (diff < 30) {
          final weeks = (diff / 7).floor();
          return '$weeks周前';
        } else if (diff < 365) {
          final months = (diff / 30).floor();
          return '$months个月前';
        } else {
          return _formatDateLabel(dateKey);
        }
      }
    } catch (e) {
      return _formatDateLabel(dateKey);
    }
  }

  /// 获取资源的月份键（yyyy-MM格式）
  static String _getMonthKey(AssetEntity asset, AlbumSortType sortType) {
    DateTime dateTime;
    switch (sortType) {
      case AlbumSortType.shootTime:
        dateTime = asset.createDateTime;
        break;
      case AlbumSortType.uploadTime:
        dateTime = asset.modifiedDateTime;
        break;
      case AlbumSortType.name:
        dateTime = asset.createDateTime;
        break;
    }
    final year = dateTime.year.toString().padLeft(4, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    return '$year-$month';
  }

  /// 格式化月份标签（yyyy年M月）
  static String _formatMonthLabel(String monthKey) {
    if (monthKey.isEmpty) return '';
    try {
      final parts = monthKey.split('-');
      if (parts.length != 2) return monthKey;
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      return '$year年$month月';
    } catch (e) {
      return monthKey;
    }
  }
}

