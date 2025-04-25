import 'package:encrypt/encrypt.dart';

class EncryptionManager {
  static Map<String, String> encryptMessage(String message, String token) {
    final key = Key.fromUtf8(token.substring(0, 32));
    final encrypter = Encrypter(AES(key));
    final iv = IV.fromLength(16);
    final encrypted = encrypter.encrypt(message, iv: iv);
    return {
      'base64':
          encrypted.base64, // Base64 encoded string of the encrypted message
      'iv': iv.base64, // Base64 encoded string of the IV
    }; // Return the Encrypted object
  }

  // Helper function to create Encrypted object from a base64 string and the IV
  static String decryptFromBase64(Map<String, String> data, String token) {
    final encryptedBase64 = data['base64']!;
    final ivBase64 = data['iv']!;
    // Convert the base64 string back to IV
    final iv = IV.fromBase64(ivBase64);
    final key = Key.fromUtf8(token.substring(0, 32));
    final encrypter = Encrypter(AES(key));
    // To decrypt from base64, we need to reconstruct the IV.
    // The 'encrypt' package conveniently stores the IV within the Encrypted object.
    // So, we can directly use the base64 encoded string.
    final encrypted = Encrypted.fromBase64(encryptedBase64);
    return encrypter.decrypt(encrypted, iv: iv);
  }
}
