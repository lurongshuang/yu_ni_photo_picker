import 'package:flutter_animate/flutter_animate.dart';

class VideoData {
  Duration duration = 0.seconds;
  double width = 0;
  double height = 0;
  bool fullScreen = false;
  bool videoRenderStart = false;
  int degree = 0;
  int? posMilli;
  int loadingPercent = 0;
  double? aspectRatio;

  void reset() {
    duration = 0.seconds;
    width = 0;
    height = 0;
    fullScreen = false;
    videoRenderStart = false;
    degree = 0;
    posMilli = 0;
    loadingPercent = 0;
    aspectRatio = 1;
  }
}

