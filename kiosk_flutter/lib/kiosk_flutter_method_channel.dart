import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'kiosk_flutter_platform_interface.dart';

/// An implementation of [KioskFlutterPlatform] that uses method channels.
class MethodChannelKioskFlutter extends KioskFlutterPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('kiosk_flutter');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<String?> getDummyMessage() async {
    final String? message = await methodChannel.invokeMethod<String>('getDummyMessage');
    return message;
  }
}
