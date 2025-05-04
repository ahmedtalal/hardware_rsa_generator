import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hardware_rsa_generator/hardware_rsa_generator_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelHardwareRsaGenerator platform =
      MethodChannelHardwareRsaGenerator();
  const MethodChannel channel = MethodChannel('hardware_rsa_generator');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('generateKeyPair', () async {
    expect(await platform.generateKeyPairStatus(),
        'generate key pair successfully');
  });

  test('getPublicKey', () async {
    final String? publicKey = await platform.getPublicKey();
    expect(publicKey?.isNotEmpty, true);
  });

  test('signData', () async {
    final data = Uint8List.fromList('Hello, World!'.codeUnits);
    final String? signature = await platform.signData(data);
    expect(signature?.isNotEmpty, true);
  });
}
