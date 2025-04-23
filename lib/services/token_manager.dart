import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenManager {
  static const _storage = FlutterSecureStorage();
  static const _prefix = 'chat_token_';

  static Future<void> saveToken(String chatId, String token) async {
    await _storage.write(key: '$_prefix$chatId', value: token);
  }

  static Future<String?> getToken(String chatId) async {
    return await _storage.read(key: '$_prefix$chatId');
  }
}
