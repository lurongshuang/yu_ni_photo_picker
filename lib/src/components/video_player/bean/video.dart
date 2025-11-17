import 'dart:io';

class Video {
  Video({
    required this.id,
    this.url,
    this.file,
    this.width,
    this.height,
    this.aspectRatio,
    this.cover,
  }) {
    assert((url != null || file != null));
  }

  String id;
  String? url;
  File? file;
  int? width;
  int? height;
  double? aspectRatio;
  String? cover;

  bool get isLandscape =>
      aspectRatio != null && aspectRatio! > 0 ? aspectRatio! > 1 : true;
}

