import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_flutter/kiosk_flutter.dart';
import 'package:kiosk_flutter/kiosk_flutter_platform_interface.dart';
import 'package:kiosk_flutter/kiosk_flutter_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockKioskFlutterPlatform
    with MockPlatformInterfaceMixin
    implements KioskFlutterPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final KioskFlutterPlatform initialPlatform = KioskFlutterPlatform.instance;

  test('$MethodChannelKioskFlutter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelKioskFlutter>());
  });

  test('getPlatformVersion', () async {
    KioskFlutter kioskFlutterPlugin = KioskFlutter();
    MockKioskFlutterPlatform fakePlatform = MockKioskFlutterPlatform();
    KioskFlutterPlatform.instance = fakePlatform;

    expect(await kioskFlutterPlugin.getPlatformVersion(), '42');
  });
}
