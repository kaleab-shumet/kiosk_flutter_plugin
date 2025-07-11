import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'kiosk_flutter_method_channel.dart';

abstract class KioskFlutterPlatform extends PlatformInterface {
  /// Constructs a KioskFlutterPlatform.
  KioskFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static KioskFlutterPlatform _instance = MethodChannelKioskFlutter();

  /// The default instance of [KioskFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelKioskFlutter].
  static KioskFlutterPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [KioskFlutterPlatform] when
  /// they register themselves.
  static set instance(KioskFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<String?> getDummyMessage() {
    throw UnimplementedError('getDummyMessage() has not been implemented.');
  }


  Future<List<Map<String, String?>>> getMissingPermissions() {
    throw UnimplementedError('getMissingPermissions() has not been implemented.');
  }

  Future<void> openPermissionSettings(String permissionType) {
    throw UnimplementedError('openPermissionSettings() has not been implemented.');
  }

  Future<bool?> isKioskModeActive() {
    throw UnimplementedError('isKioskModeActive() has not been implemented.');
  }

  Future<void> startKioskMode() {
    throw UnimplementedError('startKioskMode() has not been implemented.');
  }

  Future<void> stopKioskMode() {
    throw UnimplementedError('stopKioskMode() has not been implemented.');
  }

  Future<bool?> isSetAsDefaultLauncher() {
    throw UnimplementedError('isSetAsDefaultLauncher() has not been implemented.');
  }

  Future<void> openSettings(String setting) {
    throw UnimplementedError('openSettings() has not been implemented.');
  }
}
