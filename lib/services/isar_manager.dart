import 'package:isar/isar.dart';
import 'package:parla/models/chat_message.dart';
import 'package:path_provider/path_provider.dart';

class IsarManager {
  static final IsarManager _instance = IsarManager._internal();
  factory IsarManager() => _instance;

  late final Isar _isar;
  bool isInitialized = false;

  IsarManager._internal();

  Future<void> init() async {
    if (isInitialized) return;
    final dir = await getApplicationDocumentsDirectory();
    _isar = Isar.open(schemas: [ChatMessageSchema], directory: dir.path);
    isInitialized = true;
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

  //Is message already saved?
  bool isMessageSaved(String userId, String messageId) {
    final message =
        _isar.chatMessages
            .where()
            .senderIdEqualTo(userId)
            .chatIdEqualTo(messageId)
            .findFirst();
    return message != null;
  }

  Future<void> deleteMessage(String userId, String messageId) async {
    await _isar.writeAsync((isar) {
      isar.chatMessages
          .where()
          .senderIdEqualTo(userId)
          .chatIdEqualTo(messageId)
          .deleteFirst();
    });
  }

  Future<void> deleteAllMessages(String senderId) async {
    await _isar.writeAsync((isar) {
      isar.chatMessages.where().senderIdEqualTo(senderId).deleteAll();
    });
  }
}
