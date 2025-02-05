// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:hardware_rsa_generator/hardware_rsa_generator.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('generateKeyPair test', (WidgetTester tester) async {
    final HardwareRsaGenerator plugin = HardwareRsaGenerator();
    final String? keyStatus = await plugin.generateKeyPair();
    expect(keyStatus?.isNotEmpty, true);
  });

  testWidgets('generateKeyPair test', (WidgetTester tester) async {
    final HardwareRsaGenerator plugin = HardwareRsaGenerator();
    final String? publicKey = await plugin.getPublicKey();
    expect(publicKey?.isNotEmpty, true);
  });

  testWidgets('signData test', (WidgetTester tester) async {
    final HardwareRsaGenerator plugin = HardwareRsaGenerator();
    final data = Uint8List.fromList('Hello, World!'.codeUnits);
    final String? signature = await plugin.signData(data);
    expect(signature?.isNotEmpty, true);
  });
}
