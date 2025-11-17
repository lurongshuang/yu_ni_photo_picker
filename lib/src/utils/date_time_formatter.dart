import 'package:intl/intl.dart';

class DateTimeFormatter {
  /// 将时间戳（毫秒）或 DateTime 对象格式化为指定字符串。
  ///
  /// [timestamp] 必须是毫秒级时间戳（int）或 DateTime 对象。
  /// [format] 是输出的格式字符串，默认为 'yyyy-MM-dd HH:mm:ss'。
  ///
  /// 格式占位符：
  /// yyyy: 四位年份 (例如 2023)
  /// yy: 两位年份 (例如 23)
  /// M: 月份 (1-12)
  /// MM: 两位月份 (01-12)
  /// d: 日 (1-31)
  /// dd: 两位日 (01-31)
  /// H: 24小时制小时 (0-23)
  /// HH: 两位24小时制小时 (00-23)
  /// h: 12小时制小时 (1-12)
  /// hh: 两位12小时制小时 (01-12)
  /// m: 分钟 (0-59)
  /// mm: 两位分钟 (00-59)
  /// s: 秒 (0-59)
  /// ss: 两位秒 (00-59)
  /// SSS: 毫秒 (000-999)
  /// a: 上午/下午 (AM/PM)
  /// E: 星期几缩写 (Mon, Tue)
  /// EEEE: 星期几全称 (Monday, Tuesday)
  static String formatTimestamp(
    int timestamp, {
    String format = 'yyyy-MM-dd HH:mm:ss',
    // bool isUtc = true,
  }) {
    if (timestamp == 0) {
      return "";
    }
    DateTime dateTime;
    dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final DateFormat formatter = DateFormat(format);
    return formatter.format(dateTime);
  }

  /// 将秒级时间戳格式化为 "XXXX年X月X日" 的字符串。
  ///
  /// [secondsTimestamp] 必须是秒级时间戳（int）。
  static String formatSecondsTimestampToDate(
    int secondsTimestamp,
    // {
    // bool isUtc = true,
    // }
  ) {
    // 将秒级时间戳转换为毫秒级
    final int millisecondsTimestamp = secondsTimestamp * 1000;
    final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(
      millisecondsTimestamp,
      // isUtc: isUtc,
    );

    // 使用指定的格式 "yyyy年M月d日"
    final DateFormat formatter = DateFormat('yyyy年M月d日');
    return formatter.format(dateTime);
  }

  /// 将毫秒级时间戳格式化为易读的字符串。
  ///
  /// 行为规则：
  /// - 若时间差在 24 小时以内：返回相对时间，例如「X秒前」「X分钟前」「X小时前」。
  /// - 若时间差在 24 小时及以上：返回具体日期时间，格式为「yyyy年MM月dd日 HH:mm」。
  ///
  /// 参数说明：
  /// - [timestamp] 必须为毫秒级时间戳；当为 0 时返回空字符串。
  /// - [isUtc] 是否按 UTC 解析时间戳，默认 false。
  ///
  /// 返回值：格式化后的字符串。
  static String formatRelativeOrDateTime(
    int timestamp,
    // , {bool isUtc = false}
  ) {
    if (timestamp == 0) {
      return "";
    }

    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    final int diffMs = nowMs - timestamp;

    const int secondMs = 1000;
    const int minuteMs = 60 * secondMs;
    const int hourMs = 60 * minuteMs;
    const int dayMs = 24 * hourMs;

    if (diffMs < minuteMs) {
      final int seconds = (diffMs / secondMs).clamp(0, 59).floor();
      return seconds <= 0 ? '1秒前' : '$seconds秒前';
    } else if (diffMs < hourMs) {
      final int minutes = (diffMs / minuteMs).floor();
      return '$minutes分钟前';
    } else if (diffMs < dayMs) {
      final int hours = (diffMs / hourMs).floor();
      return '$hours小时前';
    }

    final DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(
      timestamp,
      // isUtc: isUtc,
    );
    final DateFormat formatter = DateFormat('yyyy年MM月dd日 HH:mm');
    return formatter.format(dateTime);
  }
}

