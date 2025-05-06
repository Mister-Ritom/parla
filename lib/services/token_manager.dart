import 'dart:developer';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenManager {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  static const _prefix = 'chat_token_';

  static Future<void> saveToken(String chatId, String token) async {
    log('Saving token for chatId: $chatId');
    await _storage.write(key: '$_prefix$chatId', value: token);
    final allTokens = await _storage.readAll();
    log('All tokens: $allTokens');
  }

  static Future<String?> getToken(String chatId) async {
    return await _storage.read(key: '$_prefix$chatId');
  }

  static Future<void> deleteToken(String chatId) async {
    log('Deleting token for chatId: $chatId');
    await _storage.delete(key: '$_prefix$chatId');
  }
}
