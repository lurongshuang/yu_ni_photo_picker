import 'package:image_picker/image_picker.dart';
import 'package:blurhash_ffi/blurhash_ffi.dart';

class PhotoPickerFile {
  XFile? xFile;
  String fileName;
  bool isLivePhoto;
  String? mediaUrl;
  bool sendOriginal;
  bool sendLocation;
  bool sendLiveVideo;
  String? blurHash;
  BlurhashFfiImage? blurHashImage;

  PhotoPickerFile({
    required this.xFile,
    this.fileName = '',
    this.isLivePhoto = false,
    this.mediaUrl,
    this.sendOriginal = false,
    this.sendLocation = false,
    this.sendLiveVideo = false,
    this.blurHash,
    this.blurHashImage,
  });
}
