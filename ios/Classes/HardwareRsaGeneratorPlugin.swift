import Flutter
import UIKit
import Security

public class HardwareRsaGeneratorPlugin: NSObject, FlutterPlugin {
    let keyAlias = "com.yourapp.rsa_key"

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "hardware_rsa_generator", binaryMessenger: registrar.messenger())
        let instance = HardwareRsaGeneratorPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
            case "generateKeyPair":
            do{
               let success = self.generateKeyPair()
               DispatchQueue.main.async {
                   if success==true {
                    result("generate key pair successfully")
                     }else {
                     result("generate key pair failed")
                    }
               }
            }catch{
             DispatchQueue.main.async {
                        result(FlutterError(code: "ERROR", message: error.localizedDescription, details: nil))
                    }
            }
            case "getPublicKey":
                result(self.getPublicKey())
            case "signData":
                let args = call.arguments as! [String: Any]
                let data = args["data"] as! FlutterStandardTypedData
                result(self.signData(data: data.data))
            default:
                result(FlutterMethodNotImplemented)
        }
    }

    private func generateKeyPair() -> Bool {
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits as String: 3072,
            kSecAttrApplicationTag as String: keyAlias,
            kSecAttrIsPermanent as String: true,  // Ensures key is stored persistently
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            if let error = error {
                print("❌ Key pair generation failed: \(error.takeRetainedValue())")
            }
            return false
        }

        let publicKey = SecKeyCopyPublicKey(privateKey)
        print("✅ RSA Key Pair Generated Successfully")
        return true
    }

    private func getPublicKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keyAlias,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
            kSecReturnRef as String: true
        ]

        var key: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &key)

        if status != errSecSuccess {
            print("❌ Public key retrieval failed: \(status)")
            return nil
        }

        if let publicKey = key as! SecKey? {
            var error: Unmanaged<CFError>?
            guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) else {
                if let error = error {
                    print("❌ Failed to get public key representation: \(error.takeRetainedValue())")
                }
                return nil
            }
            return (publicKeyData as Data).base64EncodedString()
        }

        return nil
    }

    private func signData(data: Data) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: keyAlias,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate, // Explicitly requesting private key
            kSecReturnRef as String: true
        ]

        var key: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &key)

        if status != errSecSuccess {
            print("❌ Private key not found: \(status)")
            return nil
        }

        guard let privateKey = key as! SecKey? else {
            print("❌ Retrieved key is null")
            return nil
        }

        var error: Unmanaged<CFError>?
        let signedData = SecKeyCreateSignature(privateKey, .rsaSignatureMessagePKCS1v15SHA256, data as CFData, &error)

        if let error = error {
            print("❌ Error signing data: \(error.takeRetainedValue())")
            return nil
        }

        print("✅ Data successfully signed")
        return signedData as Data?
    }
}
