import 'package:flutter_test/flutter_test.dart';
import 'package:hardware_rsa_generator/hardware_rsa_generator.dart';
import 'package:hardware_rsa_generator/hardware_rsa_generator_platform_interface.dart';
import 'package:hardware_rsa_generator/hardware_rsa_generator_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockHardwareRsaGeneratorPlatform
    with MockPlatformInterfaceMixin
    implements HardwareRsaGeneratorPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final HardwareRsaGeneratorPlatform initialPlatform = HardwareRsaGeneratorPlatform.instance;

  test('$MethodChannelHardwareRsaGenerator is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelHardwareRsaGenerator>());
  });

  test('getPlatformVersion', () async {
    HardwareRsaGenerator hardwareRsaGeneratorPlugin = HardwareRsaGenerator();
    MockHardwareRsaGeneratorPlatform fakePlatform = MockHardwareRsaGeneratorPlatform();
    HardwareRsaGeneratorPlatform.instance = fakePlatform;

    expect(await hardwareRsaGeneratorPlugin.getPlatformVersion(), '42');
  });
}
