import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'hardware_rsa_generator_method_channel.dart';

abstract class HardwareRsaGeneratorPlatform extends PlatformInterface {
  /// Constructs a HardwareRsaGeneratorPlatform.
  HardwareRsaGeneratorPlatform() : super(token: _token);

  static final Object _token = Object();

  static HardwareRsaGeneratorPlatform _instance = MethodChannelHardwareRsaGenerator();

  /// The default instance of [HardwareRsaGeneratorPlatform] to use.
  ///
  /// Defaults to [MethodChannelHardwareRsaGenerator].
  static HardwareRsaGeneratorPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [HardwareRsaGeneratorPlatform] when
  /// they register themselves.
  static set instance(HardwareRsaGeneratorPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
