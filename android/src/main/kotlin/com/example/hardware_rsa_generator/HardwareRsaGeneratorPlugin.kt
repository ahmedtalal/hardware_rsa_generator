package com.example.hardware_rsa_generator

import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import android.util.Log
import androidx.annotation.RequiresApi
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.KeyStoreException
import java.security.Signature
import kotlinx.coroutines.*

/** HardwareRsaGeneratorPlugin */
class HardwareRsaGeneratorPlugin : FlutterPlugin, MethodCallHandler {

  private lateinit var channel: MethodChannel
  private val keyAlias = "RSA_KEY_ALIAS"
  private val coroutineScope = CoroutineScope(Dispatchers.IO)

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "hardware_rsa_generator")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "generateKeyPair" -> {
        coroutineScope.launch {
          try {
            generateKeyPair()
            withContext(Dispatchers.Main) { // Send result back to Flutter
              result.success("generate key pair successfully")
            }
          } catch (e: Exception) {
            result.error("GENERATE_KEY_PAIRS_ERROR", e.message, null)
          }
        }
      }
      "getPublicKey" -> {
        try {
          result.success(getPublicKey())
        } catch (e: Exception) {
          result.error("GET_PUBLIC_KEY_ERROR", e.message, null)
        }
      }
      "signData" -> {
        try {
          val data = call.argument<ByteArray>("data")!!
          result.success(signData(data))
        } catch (e: Exception) {
          result.error("SIGN_DATA_ERROR", e.message, null)
        }
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    coroutineScope.cancel()
    channel.setMethodCallHandler(null)
  }

  @RequiresApi(Build.VERSION_CODES.M) // Required for AndroidKeyStore
  private fun generateKeyPair() {
    try {
      // Build base KeyGenParameterSpec with common parameters
      val baseSpecBuilder =
              KeyGenParameterSpec.Builder(
                              keyAlias, // Alias to identify the key
                              KeyProperties.PURPOSE_SIGN or
                                      KeyProperties.PURPOSE_VERIFY // Allow signing and verifying
                      )
                      .setDigests(
                              KeyProperties.DIGEST_SHA256,
                              KeyProperties.DIGEST_SHA512
                      ) // Supported hash algorithms
                      .setSignaturePaddings(
                              KeyProperties.SIGNATURE_PADDING_RSA_PKCS1
                      ) // Use PKCS#1 padding
                      .setKeySize(2048) // Key size in bits
                      .setUserAuthenticationRequired(false) // No user auth required to use the key

      // Attempt to use StrongBox (secure hardware-backed keystore) if supported
      val strongBoxSpec =
              if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                baseSpecBuilder.setIsStrongBoxBacked(true).build()
              } else {
                throw UnsupportedOperationException(
                        "VERSION.SDK_INT < P"
                ) // StrongBox not available on API < 28
              }

      // Generate key pair using AndroidKeyStore and StrongBox
      val keyGen = KeyPairGenerator.getInstance(KeyProperties.KEY_ALGORITHM_RSA, "AndroidKeyStore")
      keyGen.initialize(strongBoxSpec)
      keyGen.generateKeyPair()
      Log.d("KeyGen", "Key generated using StrongBox (secure element).")
    } catch (e: Exception) {
      // StrongBox unavailable or failed; fall back to TEE or software-backed
      Log.w("KeyGen", "StrongBox unavailable: ${e.message}. Falling back.")

      try {
        // Rebuild spec without StrongBox
        val fallbackSpec =
                KeyGenParameterSpec.Builder(
                                keyAlias,
                                KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY
                        )
                        .setDigests(KeyProperties.DIGEST_SHA256, KeyProperties.DIGEST_SHA512)
                        .setSignaturePaddings(KeyProperties.SIGNATURE_PADDING_RSA_PKCS1)
                        .setKeySize(2048)
                        .setUserAuthenticationRequired(false)
                        .setIsStrongBoxBacked(false) // Explicitly disable StrongBox
                        .build()

        // Generate key pair using fallback (likely TEE or software-based)
        val keyGen =
                KeyPairGenerator.getInstance(KeyProperties.KEY_ALGORITHM_RSA, "AndroidKeyStore")
        keyGen.initialize(fallbackSpec)
        keyGen.generateKeyPair()
        Log.d("KeyGen", "Key generated using fallback (TEE or software-backed).")
      } catch (ex: Exception) {
        // Final failure to generate key
        Log.e("KeyGen", "Key generation failed: ${ex.message}")
      }
    }
  }

  private fun getPublicKey(): String {
    // Access the AndroidKeyStore instance
    val keyStore = KeyStore.getInstance("AndroidKeyStore")
    keyStore.load(null) // Load the KeyStore (null = use default)

    // Try to retrieve the PrivateKeyEntry associated with the alias
    val privateKeyEntry = keyStore.getEntry(keyAlias, null) as? KeyStore.PrivateKeyEntry

    // If the entry exists, extract the public key from its certificate
    privateKeyEntry?.let {
      val publicKey = it.certificate.publicKey // Extract public key from the X.509 certificate
      return Base64.encodeToString(
              publicKey.encoded,
              Base64.DEFAULT
      ) // Encode public key as Base64 string
    }
            ?: run {
              // If no entry found for the alias, throw an exception
              throw KeyStoreException("No key found for alias $keyAlias")
            }
  }

  private fun signData(data: ByteArray): String {
    try {
      val keyStore = KeyStore.getInstance("AndroidKeyStore")
      keyStore.load(null)

      // Safely retrieve the private key
      val privateKey =
              keyStore.getKey(keyAlias, null) as? java.security.PrivateKey
                      ?: throw IllegalStateException("Private key not found or invalid")

      // Create the Signature object
      val signature =
              Signature.getInstance(
                      "SHA256withRSA"
              ) // You can change this if you prefer another algorithm like "SHA512withRSA"

      signature.initSign(privateKey) // Initialize the signature with the private key
      signature.update(data) // Supply the data to be signed

      val byte = signature.sign() // Return the final signature
      return Base64.encodeToString(byte, Base64.NO_WRAP)
    } catch (e: Exception) {
      Log.e("SignData", "Error signing data: ${e.message}")
      throw e // Re-throw the exception after logging the error
    }
  }
}
