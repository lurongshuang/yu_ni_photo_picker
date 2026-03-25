import 'package:image_picker/image_picker.dart';

class PhotoPickerFile {
  XFile? xFile;
  String fileName;
  bool isLivePhoto;
  String? mediaUrl;
  bool sendOriginal;
  bool sendLocation;
  bool sendLiveVideo;

  PhotoPickerFile({
    required this.xFile,
    required this.fileName,
    this.isLivePhoto = false,
    this.mediaUrl,
    this.sendOriginal = false,
    this.sendLocation = false,
    this.sendLiveVideo = false,
  });
}

