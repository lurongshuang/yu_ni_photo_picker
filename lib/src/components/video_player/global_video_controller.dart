import 'dart:collection';

import 'base/video_player.dart';

class GlobalVideoController {
  final LinkedHashMap<String, BaseVideoPlayer> _videoPlayerCache = LinkedHashMap();
  final int maxMemoryVideoCount = 3;
  BaseVideoPlayer? currentPlayer;

  /// 调用此方法，将player放入全局缓存。如果缓存数量超出最大值，则移除最早的视频，这个时候会触发realPlayer的release()方法，会导致player实例的变化。
  /// 因此，使用这个方法前，应该监听playerInstanceCode的变化，发生改变后重新获取realPlayer
  void addCache(key, BaseVideoPlayer player) {
    _videoPlayerCache.remove(key); // remove再添加，是为了改变顺序
    _videoPlayerCache[key] = player;
    checkCache();
  }

  BaseVideoPlayer? getFromCache(key) {
    return _videoPlayerCache[key];
  }

  BaseVideoPlayer? removeCache(key) {
    return _videoPlayerCache.remove(key);
  }

  // 如果缓存中的视频数量超过了最大值，则移除最早的视频
  void checkCache() {
    if (maxMemoryVideoCount > 1 &&
        _videoPlayerCache.length > maxMemoryVideoCount) {
      String firstKey = _videoPlayerCache.keys.first;
      BaseVideoPlayer? player = _videoPlayerCache.remove(firstKey);
      if (player != null) {
        if (player != currentPlayer) {
          // 清除内存中的player，应该避免调用dispose。否则会导致业务持有的player不可用，dispose应该只有在业务完全可知的情况下主动调用。
          player.release();
        } else {
          addCache(firstKey, player);
        }
      }
    }
  }

  void disposeAll() {
    try {
      Map<int, BaseVideoPlayer>.from(_videoPlayerCache).forEach((key, player) {
        player.dispose();
      });
    } catch (e) {
      // log.error("disposeAll  error.", [e]);
    }
    currentPlayer = null;
    _videoPlayerCache.clear();
  }

  void releaseAllWithoutCurrent() {
    _videoPlayerCache.removeWhere((key, player) {
      if (player != currentPlayer) {
        // log.error(
        //   'in releaseAllWithoutCurrent method. release player. ${player.hashCode}',
        // );
        player.release();
        return true;
      }
      return false;
    });
  }
}

