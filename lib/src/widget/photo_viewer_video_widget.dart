import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';
import 'package:yu_ni_photo_picker/src/constants/constants.dart';
import '../components/image_view/image_error.dart';
import '../components/video_player/play_button_overlay_widget.dart';
import '../service/photo_picker_service.dart';
import 'package:yuni_widget/yuni_widget.dart';

/// 视频查看器组件（简化版本，使用video_player）
class PhotoViewerVideoWidget extends ConsumerStatefulWidget {
  final AssetEntity asset;

  // final VoidCallback? onTap;

  const PhotoViewerVideoWidget({
    super.key,
    required this.asset,
    // this.onTap
  });

  @override
  ConsumerState<PhotoViewerVideoWidget> createState() =>
      _PhotoViewerVideoWidgetState();
}

class _PhotoViewerVideoWidgetState
    extends ConsumerState<PhotoViewerVideoWidget> {
  VideoPlayerController? _videoPlayerController;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;
  ValueNotifier<bool> isPlayNotifier = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    isPlayNotifier.value = false;
    _initializeVideo();
  }

  @override
  void dispose() {
    isPlayNotifier.value = false;
    _videoPlayerController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    try {
      final file = await widget.asset.originFile;
      if (file != null) {
        _videoPlayerController = VideoPlayerController.file(file);
        await _videoPlayerController!.initialize();

        _videoPlayerController!.addListener(() {
          if (_videoPlayerController!.value.isPlaying) {
            isPlayNotifier.value = true;
          } else {
            isPlayNotifier.value = false;
          }
        });

        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      } else {
        throw Exception('无法获取视频文件');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorWidget();
    }

    if (!_isInitialized || _videoPlayerController == null) {
      return _buildLoadingWidget();
    }

    return _buildVideoPlayer();
  }

  /// 构建视频播放器
  Widget _buildVideoPlayer() {
    final config = YuniWidgetConfig.instance;
    return Center(
      child: Material(
        color: config.colors.onBackground,
        child: Stack(
          children: [
            // 视频播放器层
            Center(child: _buildVideoPlayerLayer()),
            // 缩略图和播放按钮层
            _buildThumbnailLayer(),
          ],
        ),
      ),
    );
  }

  /// 构建视频播放器层
  Widget _buildVideoPlayerLayer() {
    return ValueListenableBuilder(
      key: ValueKey(1),
      valueListenable: isPlayNotifier,
      builder: (context, isPlaying, child) {
        if (isPlaying) {
          return AspectRatio(
            aspectRatio: _videoPlayerController!.value.aspectRatio,
            child: VideoPlayer(_videoPlayerController!),
          );
        }
        return Container(key: ValueKey(1));
      },
    );
  }

  /// 构建缩略图层
  Widget _buildThumbnailLayer() {
    return ValueListenableBuilder(
      valueListenable: isPlayNotifier,
      builder: (context, isPlaying, _) {
        return AnimatedSwitcher(
          duration: Duration(milliseconds: 200),
          child:
              isPlaying
                  ? Container(key: ValueKey(1))
                  : _buildThumbnailWithPlayButton(),
        );
      },
    );
  }

  /// 构建缩略图和播放按钮
  Widget _buildThumbnailWithPlayButton() {
    return Stack(
      key: ValueKey(0),
      children: [
        // 缩略图
        _buildThumbnail(),
        // 播放按钮
        GestureDetector(
          onTap: () {
            // 优先处理视频播放
            _playVideo();
          },
          child: Center(
            child: PlayButtonOverlayWidget(size: PlayButtonSize.large),
          ),
        ),
      ],
    );
  }

  /// 构建缩略图
  Widget _buildThumbnail() {
    return FutureBuilder<Uint8List?>(
      future: PhotoPickerService.getThumbnail(
        widget.asset,
        defaultAssetGridPreviewSize,
        // quality: 10,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return Center(
            child: Image.memory(
              snapshot.data!,
              fit: BoxFit.cover,
              width: widget.asset.orientatedWidth.toDouble(),
              height: widget.asset.orientatedHeight.toDouble(),
            ),
          ).animate().fadeIn();
        }
        return Container(color: YuniWidgetConfig.instance.colors.onBackground);
      },
    );
  }

  /// 播放视频
  void _playVideo() {
    _videoPlayerController?.play();
    isPlayNotifier.value = true;
  }

  Widget _buildLoadingWidget() {
    return Container(
      color: YuniWidgetConfig.instance.colors.onBackground,
      child: Center(child: YLoading.circular()),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: YuniWidgetConfig.instance.colors.onBackground,
      alignment: Alignment.center,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ImageError(),
            YText.bodyMediumRegular(_errorMessage ?? ""),
          ],
        ),
      ),
    );
  }
}
