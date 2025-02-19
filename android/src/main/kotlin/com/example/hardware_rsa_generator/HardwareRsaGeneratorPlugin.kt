package com.example.hardware_rsa_generator

import android.annotation.TargetApi
import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import androidx.annotation.RequiresApi
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.Signature
import android.util.Base64
import kotlinx.coroutines.*



/** HardwareRsaGeneratorPlugin */
class HardwareRsaGeneratorPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private val keyAlias = "RSA_KEY_ALIAS"

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "hardware_rsa_generator")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
        "generateKeyPair" -> {
          GlobalScope.launch(Dispatchers.IO) { // Run in background thread
            try {
              generateKeyPair()
              withContext(Dispatchers.Main){ // Send result back to Flutter
                result.success("generate key pair successfully")
              }
            }catch (e:Exception){
              result.error("GENERATE_KEY_PAIRS_ERROR", e.message, null)
            }
          }
        }
        "getPublicKey" -> {
          try {
            result.success(getPublicKey())
          }catch (e:Exception){
            result.error("GET_PUBLIC_KEY_ERROR", e.message, null)
          }
        }
        "signData" -> {
          try {
            val data = call.argument<ByteArray>("data")!!
            result.success(signData( data))
          }catch (e:Exception){
            result.error("SIGN_DATA_ERROR", e.message, null)
          }
        }
        else -> {
          result.notImplemented()
        }
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  @TargetApi(Build.VERSION_CODES.M)
  private fun generateKeyPair() {
    val keyGen = KeyPairGenerator.getInstance(KeyProperties.KEY_ALGORITHM_RSA, "AndroidKeyStore")
    val spec = KeyGenParameterSpec.Builder(
      keyAlias,
      KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY // Use signing and verification
    )
      .setDigests(KeyProperties.DIGEST_SHA256, KeyProperties.DIGEST_SHA512)
      .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_RSA_PKCS1) // Ensure RSA PKCS1 padding is used
      .setSignaturePaddings(KeyProperties.SIGNATURE_PADDING_RSA_PKCS1)  // Include signature padding
      .setKeySize(3072) // Use 3072-bit keys
      .setUserAuthenticationRequired(false) // Disable user authentication for simplicity
      .build()

    keyGen.initialize(spec)
    keyGen.generateKeyPair()
  }

  private fun getPublicKey(): String {
    val keyStore = KeyStore.getInstance("AndroidKeyStore")
    keyStore.load(null)
    val publicKey = keyStore.getCertificate(keyAlias).publicKey
    return Base64.encodeToString(publicKey.encoded, Base64.DEFAULT)
  }

  private fun signData(data: ByteArray): ByteArray {
    val keyStore = KeyStore.getInstance("AndroidKeyStore")
    keyStore.load(null)
    val privateKey = keyStore.getKey(keyAlias, null) as? java.security.PrivateKey
      ?: throw IllegalStateException("Private key not found or invalid")
    val signature = Signature.getInstance("SHA256withRSA") // Use appropriate digest/signature algorithm
    signature.initSign(privateKey) // Initialize signing with private key
    signature.update(data) // Supply data to be signed

    return signature.sign() // Generate the signature
  }
}
