import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'video_thumbnail_method_channel.dart';

abstract class VideoThumbnailPlatform extends PlatformInterface {
  /// Constructs a VideoThumbnailPlatform.
  VideoThumbnailPlatform() : super(token: _token);

  static final Object _token = Object();

  static VideoThumbnailPlatform _instance = MethodChannelVideoThumbnail();

  /// The default instance of [VideoThumbnailPlatform] to use.
  ///
  /// Defaults to [MethodChannelVideoThumbnail].
  static VideoThumbnailPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [VideoThumbnailPlatform] when
  /// they register themselves.
  static set instance(VideoThumbnailPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
