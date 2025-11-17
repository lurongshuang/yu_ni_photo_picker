import 'dart:math';

import 'package:yu_ni_photo_picker/src/model/photo_picker_state.dart';

/// 资产网格渲染元素类型
/// - assets: 实际的资源分片（用于Grid的行渲染）
/// - groupDividerTitle: 小标题（通常为“某一天”的日期标签）
/// - monthTitle: 月份大标题（“某年某月”），可按需合并整月

enum RenderAssetGridElementType { assets, groupDividerTitle, monthTitle }

class RenderAssetGridElement {
  final RenderAssetGridElementType type; // 元素类型：标题或资源分片
  final String? title; // 标题文案（当为标题类型时使用）
  final DateTime date; // 归一化日期（day/month级别）
  final int count; // 本元素包含的资源数量
  final int offset; // 在全局资产列表中的起始偏移
  final int totalCount; // 标题对应的总数量（用于统计/展示）

  const RenderAssetGridElement(
    this.type, {
    this.title,
    required this.date,
    this.count = 0,
    this.offset = 0,
    this.totalCount = 0,
  });
}

enum GroupAssetsBy { day, month, none }

class RenderList {
  final List<RenderAssetGridElement> elements; // 渲染元素序列（标题 + 资源分片）
  final List<ChoiceAssetEntity> allAssets; // 原始资产（按时间排序）
  final int totalAssets; // 资产总数

  RenderList(this.elements, this.allAssets) : totalAssets = allAssets.length;

  bool get isEmpty => totalAssets == 0;

  List<ChoiceAssetEntity> loadAssets(int offset, int count) {
    return allAssets.sublist(offset, offset + count); // 提供局部分片给Grid渲染
  }

  ChoiceAssetEntity loadAsset(int index) => allAssets[index];

  /// 将原始资产列表转换为渲染列表
  /// - 支持：不分组、按天分组、按月分组
  /// - 性能：按固定分片大小 sectionSize 切分，避免大列表构建开销
  static RenderList fromAssets(List<ChoiceAssetEntity> assets, GroupAssetsBy groupBy) {
    final List<RenderAssetGridElement> elements = [];

    const sectionSize = 60; // 单个资源分片最多包含的条目数

    if (groupBy == GroupAssetsBy.none) {
      final total = assets.length;
      for (int i = 0; i < total; i += sectionSize) {
        final date = assets[i].asset.createDateTime;
        final count = i + sectionSize > total ? total - i : sectionSize;
        elements.add(RenderAssetGridElement(
          RenderAssetGridElementType.assets,
          date: DateTime(date.year, date.month, date.day),
          count: count,
          totalCount: total,
          offset: i,
        ));
      }
      return RenderList(elements, assets);
    }

    int offset = 0;
    DateTime? last;
    DateTime? current;
    int lastOffset = 0;
    int count = 0;
    int monthCount = 0;
    int lastMonthIndex = 0;

    /// 在“按天分组”时，当某个月的资源量较小（<=30）时，将该月合并为仅显示月份标题
    /// 并移除该月内已添加的每日小标题，保持与 Immich 行为一致
    void mergeMonth() {
      if (last != null && groupBy == GroupAssetsBy.day && monthCount <= 30 && elements.length > lastMonthIndex + 1) {
        final e = elements[lastMonthIndex];
        elements[lastMonthIndex] = RenderAssetGridElement(
          RenderAssetGridElementType.monthTitle,
          date: e.date,
          count: monthCount,
          totalCount: monthCount,
          offset: e.offset,
          title: _formatMonthLabel(e.date),
        );
        elements.removeRange(lastMonthIndex + 1, elements.length);
      }
    }

    String formatDayLabel(DateTime d) => '${d.year}年${d.month}月${d.day}日';

    /// 将当前日期 d 对应的资源按分片写入 elements，必要时追加月份/日标题
    void addElems(DateTime d) {
      final bool newMonth = last == null || last.year != d.year || last.month != d.month;
      if (newMonth) {
        mergeMonth();
        lastMonthIndex = elements.length;
        monthCount = 0;
      }
      for (int j = 0; j < count; j += sectionSize) {
        final type = j == 0
            ? (groupBy != GroupAssetsBy.month && newMonth
                ? RenderAssetGridElementType.monthTitle
                : RenderAssetGridElementType.groupDividerTitle)
            : RenderAssetGridElementType.assets;
        final sectionCount = j + sectionSize > count ? count - j : sectionSize;
        elements.add(RenderAssetGridElement(
          type,
          date: d,
          count: sectionCount,
          totalCount: groupBy == GroupAssetsBy.day ? sectionCount : count,
          offset: lastOffset + j,
          title: j == 0
              ? (type == RenderAssetGridElementType.monthTitle
                  ? _formatMonthLabel(d)
                  : (groupBy == GroupAssetsBy.day ? formatDayLabel(d) : _formatMonthLabel(d)))
              : null,
        ));
      }
      monthCount += count;
    }

    // 批量扫描原始资产，按月份/日期切换累积，并调用 addElems 输出渲染元素
    while (offset < assets.length) {
      final batchEnd = min(offset + 50000, assets.length);
      for (int i = offset; i < batchEnd; i++) {
        final date0 = assets[i].asset.createDateTime;
        final d = DateTime(date0.year, date0.month, groupBy == GroupAssetsBy.month ? 1 : date0.day);
        current ??= d;
        if (current != d) {
          addElems(current);
          last = current;
          current = d;
          lastOffset = i;
          count = 0;
        }
        count++;
      }
      offset = batchEnd;
    }
    if (count > 0 && current != null) {
      addElems(current);
      mergeMonth();
    }
    return RenderList(elements, assets);
  }

  /// 月份标签格式化
  static String _formatMonthLabel(DateTime d) => '${d.year}年${d.month}月';
}
