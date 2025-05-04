import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'hardware_rsa_generator_platform_interface.dart';

/// An implementation of [HardwareRsaGeneratorPlatform] that uses method channels.
class MethodChannelHardwareRsaGenerator extends HardwareRsaGeneratorPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('hardware_rsa_generator');

  @override
  Future<String?> generateKeyPairStatus() async {
    final keyStatus =
        await methodChannel.invokeMethod<String>('generateKeyPair');
    return keyStatus;
  }

  @override
  Future<String?> getPublicKey() async {
    final publicKey = await methodChannel.invokeMethod<String>('getPublicKey');
    return publicKey;
  }

  @override
  Future<String?> signData(Uint8List data) async {
    final signature =
        await methodChannel.invokeMethod('signData', {'data': data});
    return signature;
  }
}
