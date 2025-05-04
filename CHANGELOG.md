## 1.0.0

- In this version create flutter plugin that allows you to generate, store, and use RSA key pairs directly within the secure hardware-backed Keystore (Android) and Secure Enclave (iOS).

## 1.0.1

- In this version optimized performance by running cryptographic operations on a background thread.

## 1.1.0

- Added support for Secure Enclave (iOS) and Secure Element (Android).
- In Android, added a check to ensure the key is stored in the Secure Element (if available).
- In iOS, modified key generation to check for Secure Enclave availability and store the key there if supported.
- Updated `signData` method to return Base64-encoded string on both platforms (Android & iOS).
- Optimized cryptographic operations by running them on background threads.

## 1.1.1

- Fixed bug in ios
