
import 'hardware_rsa_generator_platform_interface.dart';

class HardwareRsaGenerator {
  Future<String?> getPlatformVersion() {
    return HardwareRsaGeneratorPlatform.instance.getPlatformVersion();
  }
}
