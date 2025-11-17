import 'package:flutter/material.dart';

import '../bean/video.dart';
import 'video_data.dart';

abstract class BaseVideoPlayer {
  VideoData get videoData;

  bool get isPrepared;

  bool get isError;

  bool get isPlaying;

  get state;

  get value;

  Video get video;

  void  updateVideo(Video video);

  bool get disposed;

  set closeLog(bool close);

  Future init();

  Future play();

  Future release();

  Future dispose();

  Future pause();

  Future preload();

  Future reset();

  void removeListener(lis);

  void addListener(lis);

  void onCurrentPosUpdate(Function(Duration) callback);

  void onBufferPercentUpdate(Function(int) callback);

  void onPlayerPreparedUpdate(Function(bool) callback);

  // Future<int?> setupSurface();

  get realPlayer;

  Future<void> setRate(double rate);

  Future<void> setMute(bool mute);

  Future<void> seek(double progress);

  ValueNotifier<VideoPlayerState> get playStateNotifier;

  VideoPlayerPlatform get platformPlayer;
}

/// 播放器状态枚举
enum VideoPlayerState {
  /// 初始状态
  idle,

  /// 加载中
  loading,

  /// 播放中
  playing,

  /// 暂停
  paused,

  /// 播放完成
  completed,

  /// 播放失败
  error,

  /// 缓冲中
  buffering,
}

enum VideoPlayerPlatform {
  ///腾讯播放器
  txPlayer,

  ///视频播放器kit
  videoPlayerKit,
}

