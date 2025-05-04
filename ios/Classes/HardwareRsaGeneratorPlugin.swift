import Flutter
import UIKit
import Security
import Foundation
import LocalAuthentication

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
    // Check if Secure Enclave is available on the device
    let context = LAContext()
    var error: NSError?
    let isSecureEnclaveAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

    let attributes: [String: Any] = [
        kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
        kSecAttrKeySizeInBits as String: 3072,
        kSecAttrApplicationTag as String: keyAlias,
        kSecAttrIsPermanent as String: true,  // Ensures the key is stored persistently
        kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
    ]

    // If Secure Enclave is available, use it for storing the key
    if isSecureEnclaveAvailable {
        print("Secure Enclave is available. Using it to store the key.")
        // If Secure Enclave is available, modify the attributes to store the key in the Secure Enclave
        let enclaveAttributes = attributes.merging([kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave]) { (current, _) in current }
        return createKeyPair(attributes: enclaveAttributes)
    } else {
        print("Secure Enclave is not available. Using the regular Keychain.")
        // If Secure Enclave is not available, store the key in the regular Keychain
        return createKeyPair(attributes: attributes)
    }
}

private func createKeyPair(attributes: [String: Any]) -> Bool {
    var error: Unmanaged<CFError>?
    // Try to generate the key pair with the provided attributes
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
    // Check if Secure Enclave is available on the device
    let context = LAContext()
    var error: NSError?
    let isSecureEnclaveAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

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
        
        // If Secure Enclave is available, we ensure we're getting the public key from Secure Enclave
        if isSecureEnclaveAvailable {
            print("Secure Enclave is available. Retrieving public key from Secure Enclave.")
        } else {
            print("Secure Enclave is not available. Retrieving public key from Keychain.")
        }

        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) else {
            if let error = error {
                print("❌ Failed to get public key representation: \(error.takeRetainedValue())")
            }
            return nil
        }
        
        // Return the public key as a base64-encoded string
        return (publicKeyData as Data).base64EncodedString()
    }

    return nil
}


    import Security
import LocalAuthentication

private func signData(data: Data) -> String? {
    // Check if Secure Enclave is available on the device
    let context = LAContext()
    var error: NSError?
    let isSecureEnclaveAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    
    // Attributes for accessing the private key
    let query: [String: Any] = [
        kSecClass as String: kSecClassKey,
        kSecAttrApplicationTag as String: keyAlias,
        kSecReturnRef as String: true,
        kSecAttrKeyClass as String: kSecAttrKeyClassPrivate
    ]
    
    // If Secure Enclave is available, use it for signing
    if isSecureEnclaveAvailable {
        print("Secure Enclave is available. Using it to sign data.")
        // Add Secure Enclave-specific attributes
        var enclaveAttributes = query
        enclaveAttributes[kSecAttrTokenID as String] = kSecAttrTokenIDSecureEnclave
        
        return signWithPrivateKey(attributes: enclaveAttributes, data: data)
    } else {
        print("Secure Enclave is not available. Using Keychain for signing.")
        return signWithPrivateKey(attributes: query, data: data)
    }
}

private func signWithPrivateKey(attributes: [String: Any], data: Data) -> String? {
    // Try to get the private key from Keychain or Secure Enclave
    var privateKeyRef: CFTypeRef?
    let status = SecItemCopyMatching(attributes as CFDictionary, &privateKeyRef)
    
    if status != errSecSuccess {
        print("❌ Failed to retrieve private key: \(status)")
        return nil
    }
    
    guard let privateKey = privateKeyRef as? SecKey else {
        print("❌ Failed to cast private key reference.")
        return nil
    }

    // Define the signature algorithm (RSA-SHA256 in this case)
    let algorithm: SecKeyAlgorithm = .rsaSignatureMessagePKCS1v15SHA256
    
    // Create the signature using the private key
    var error: Unmanaged<CFError>?
    guard let signedData = SecKeyCreateSignature(privateKey, algorithm, data as CFData, &error) else {
        if let error = error {
            print("❌ Signing failed: \(error.takeRetainedValue())")
        }
        return nil
    }
    
    // Convert the signature to Base64 encoded string
    let signatureData = signedData as Data
    let base64Signature = signatureData.base64EncodedString()
    print("✅ Data signed successfully")
    return base64Signature
}

}
