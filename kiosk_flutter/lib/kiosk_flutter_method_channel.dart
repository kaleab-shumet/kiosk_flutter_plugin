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

  @override
  Future<List<Map<String, String?>>> getMissingPermissions() async {
    final List<dynamic>? permissions = await methodChannel.invokeMethod<List<dynamic>>('getMissingPermissions');
    return permissions?.map((p) => Map<String, String?>.from(p as Map)).toList() ?? [];
  }

  @override
  Future<void> openPermissionSettings(String permissionType) async {
    await methodChannel.invokeMethod('openPermissionSettings', <String, dynamic>{
      'permissionType': permissionType,
    });
  }

  @override
  Future<bool?> isKioskModeActive() async {
    final bool? isActive = await methodChannel.invokeMethod<bool>('isKioskModeActive');
    return isActive;
  }

  @override
  Future<void> startKioskMode() async {
    await methodChannel.invokeMethod('startKioskMode');
  }

  @override
  Future<void> stopKioskMode() async {
    await methodChannel.invokeMethod('stopKioskMode');
  }

  @override
  Future<bool?> isSetAsDefaultLauncher() async {
    final bool? isDefault = await methodChannel.invokeMethod<bool>('isSetAsDefaultLauncher');
    return isDefault;
  }

  @override
  Future<void> openSettings(String setting) async {
    await methodChannel.invokeMethod('openSettings', <String, dynamic>{
      'setting': setting,
    });
  }
}
