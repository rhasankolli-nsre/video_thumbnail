import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'video_thumbnail_platform_interface.dart';

/// An implementation of [VideoThumbnailPlatform] that uses method channels.
class MethodChannelVideoThumbnail extends VideoThumbnailPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('video_thumbnail');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
