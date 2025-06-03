
import 'kiosk_flutter_platform_interface.dart';

class KioskFlutter {
  Future<String?> getPlatformVersion() {
    return KioskFlutterPlatform.instance.getPlatformVersion();
  }

  Future<String?> getDummyMessage() {
    return KioskFlutterPlatform.instance.getDummyMessage();
  }


  Future<List<Map<String, String?>>> getMissingPermissions() {
    return KioskFlutterPlatform.instance.getMissingPermissions();
  }

  Future<void> openPermissionSettings(String permissionType) {
    return KioskFlutterPlatform.instance.openPermissionSettings(permissionType);
  }

  Future<bool?> isKioskModeActive() {
    return KioskFlutterPlatform.instance.isKioskModeActive();
  }

  Future<void> startKioskMode() {
    return KioskFlutterPlatform.instance.startKioskMode();
  }

  Future<void> stopKioskMode() {
    return KioskFlutterPlatform.instance.stopKioskMode();
  }

  Future<bool?> isSetAsDefaultLauncher() {
    return KioskFlutterPlatform.instance.isSetAsDefaultLauncher();
  }

  Future<void> openSettings(String setting) {
    return KioskFlutterPlatform.instance.openSettings(setting);
  }
}
