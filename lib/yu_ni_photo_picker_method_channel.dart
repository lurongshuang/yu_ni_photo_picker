import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'yu_ni_photo_picker_platform_interface.dart';

/// An implementation of [YuNiPhotoPickerPlatform] that uses method channels.
class MethodChannelYuNiPhotoPicker extends YuNiPhotoPickerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('yu_ni_photo_picker');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
