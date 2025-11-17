import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'yu_ni_photo_picker_method_channel.dart';

abstract class YuNiPhotoPickerPlatform extends PlatformInterface {
  /// Constructs a YuNiPhotoPickerPlatform.
  YuNiPhotoPickerPlatform() : super(token: _token);

  static final Object _token = Object();

  static YuNiPhotoPickerPlatform _instance = MethodChannelYuNiPhotoPicker();

  /// The default instance of [YuNiPhotoPickerPlatform] to use.
  ///
  /// Defaults to [MethodChannelYuNiPhotoPicker].
  static YuNiPhotoPickerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [YuNiPhotoPickerPlatform] when
  /// they register themselves.
  static set instance(YuNiPhotoPickerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
