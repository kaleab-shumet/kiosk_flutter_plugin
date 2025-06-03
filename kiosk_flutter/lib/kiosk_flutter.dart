
import 'kiosk_flutter_platform_interface.dart';

class KioskFlutter {
  Future<String?> getPlatformVersion() {
    return KioskFlutterPlatform.instance.getPlatformVersion();
  }

  Future<String?> getDummyMessage() {
    return KioskFlutterPlatform.instance.getDummyMessage();
  }
}
