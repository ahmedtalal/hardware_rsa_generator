import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'hardware_rsa_generator_platform_interface.dart';

/// An implementation of [HardwareRsaGeneratorPlatform] that uses method channels.
class MethodChannelHardwareRsaGenerator extends HardwareRsaGeneratorPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('hardware_rsa_generator');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
