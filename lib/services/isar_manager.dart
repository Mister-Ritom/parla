import 'package:isar/isar.dart';
import 'package:parla/models/chat_message.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class IsarManager {
  static final IsarManager _instance = IsarManager._internal();
  factory IsarManager() => _instance;

  late final Isar _isar;

  IsarManager._internal();

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _isar = Isar.open(schemas: [ChatMessageSchema], directory: dir.path);
  }

  Future<void> saveMessage(ChatMessage message) async {
    await _isar.writeAsync((isar) {
      message.Id = isar.chatMessages.autoIncrement();
      isar.chatMessages.put(message);
    });
  }

  Future<List<ChatMessage>> getMessagesFrom(String userId) async {
    return _isar.chatMessages
        .where()
        .senderIdEqualTo(userId)
        .sortBySentAt()
        .findAll();
  }
}
