import 'package:flutter/services.dart';

import 'hardware_rsa_generator_platform_interface.dart';

class HardwareRsaGenerator {
  /// Generate a key pair in the secure element
  Future<String?> generateKeyPairStatus() {
    return HardwareRsaGeneratorPlatform.instance.generateKeyPairStatus();
  }

  /// Return the public key of the secure element
  Future<String?> getPublicKey() {
    return HardwareRsaGeneratorPlatform.instance.getPublicKey();
  }

  /// Return signature of the data using the secure element private key
  Future<String?> signData(Uint8List data) {
    return HardwareRsaGeneratorPlatform.instance.signData(data);
  }
}
