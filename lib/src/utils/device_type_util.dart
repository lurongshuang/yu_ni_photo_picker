import 'dart:io';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// 设备类型枚举
enum DeviceType { phone, tablet, desktop, watch, unknown }

/// 设备类型检测工具类（单例模式）
class DeviceTypeUtil {
  DeviceTypeUtil._internal();

  static final DeviceTypeUtil _instance = DeviceTypeUtil._internal();

  factory DeviceTypeUtil() => _instance;

  static DeviceTypeUtil get instance => _instance;

  DeviceType? _deviceType;
  bool _isInitialized = false;
  
  // 暴露给外部检查是否已初始化
  bool get isInitialized => _isInitialized;

  /// 初始化设备类型检测（需BuildContext）
  Future<DeviceType> initDeviceType(BuildContext context) async {
    if (_isInitialized) return _deviceType!;

    /// 桌面平台检测（包括Web的桌面模式）
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      _deviceType = DeviceType.desktop;
    }
    /// 移动设备/Web平台检测
    else {
      final double shortestSide = MediaQuery.of(context).size.shortestSide;

      /// Web平台检测
      if (kIsWeb) {
        _deviceType =
            (shortestSide < 600) ? DeviceType.phone : DeviceType.tablet;
      }
      /// Android平台检测
      else if (Platform.isAndroid) {
        _deviceType =
            (shortestSide < 600) ? DeviceType.phone : DeviceType.tablet;
      }
      /// iOS平台检测
      else if (Platform.isIOS) {
        final iosInfo = await DeviceInfoPlugin().iosInfo;
        _deviceType =
            iosInfo.model.contains("iPad")
                ? DeviceType.tablet
                : DeviceType.phone;
      }
      /// 其他平台
      else {
        _deviceType = DeviceType.unknown;
      }
    }

    _isInitialized = true;
    return _deviceType!;
  }

  /// 获取设备类型（如果未初始化，返回默认值 phone）
  DeviceType get deviceType {
    if (!_isInitialized) {
      // 如果未初始化，尝试同步检测桌面平台
      if (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux) {
        _deviceType = DeviceType.desktop;
        _isInitialized = true;
        return _deviceType!;
      }
      // 其他平台默认返回 phone
      return DeviceType.phone;
    }
    return _deviceType!;
  }

  bool get isMobile => deviceType == DeviceType.phone;

  bool get isTablet => deviceType == DeviceType.tablet;

  bool get isDesktop => deviceType == DeviceType.desktop;

  bool get isWatch => deviceType == DeviceType.watch;

  bool get isUnknown => deviceType == DeviceType.unknown;
}

