import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hardware_rsa_generator/hardware_rsa_generator.dart';
import 'package:hardware_rsa_generator/hardware_rsa_generator_platform_interface.dart';
import 'package:hardware_rsa_generator/hardware_rsa_generator_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockHardwareRsaGeneratorPlatform
    with MockPlatformInterfaceMixin
    implements HardwareRsaGeneratorPlatform {
  @override
  Future<String?> generateKeyPairStatus() =>
      Future.value('generate key pair successfully');

  @override
  Future<String?> getPublicKey() =>
      Future.value('generate key pair successfully');
  @override
  Future<String?> signData(Uint8List data) =>
      Future.value('generate key pair successfully');
}

void main() {
  final HardwareRsaGeneratorPlatform initialPlatform =
      HardwareRsaGeneratorPlatform.instance;

  test('$MethodChannelHardwareRsaGenerator is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelHardwareRsaGenerator>());
  });

  test('generateKeyPair', () async {
    HardwareRsaGenerator hardwareRsaGeneratorPlugin = HardwareRsaGenerator();
    MockHardwareRsaGeneratorPlatform fakePlatform =
        MockHardwareRsaGeneratorPlatform();
    HardwareRsaGeneratorPlatform.instance = fakePlatform;

    expect(await hardwareRsaGeneratorPlugin.generateKeyPairStatus(),
        'generate key pair successfully');
  });

  test('getPublicKey', () async {
    HardwareRsaGenerator hardwareRsaGeneratorPlugin = HardwareRsaGenerator();
    MockHardwareRsaGeneratorPlatform fakePlatform =
        MockHardwareRsaGeneratorPlatform();
    HardwareRsaGeneratorPlatform.instance = fakePlatform;
    final String? publicKey = await hardwareRsaGeneratorPlugin.getPublicKey();
    expect(publicKey?.isNotEmpty, true);
  });

  test('signData', () async {
    HardwareRsaGenerator hardwareRsaGeneratorPlugin = HardwareRsaGenerator();
    MockHardwareRsaGeneratorPlatform fakePlatform =
        MockHardwareRsaGeneratorPlatform();
    HardwareRsaGeneratorPlatform.instance = fakePlatform;
    final data = Uint8List.fromList('Hello, World!'.codeUnits);
    final String? signature = await hardwareRsaGeneratorPlugin.signData(data);
    expect(signature?.isNotEmpty, true);
  });
}
