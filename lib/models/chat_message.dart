import 'package:isar/isar.dart';

part 'chat_message.g.dart';

@collection
class ChatMessage {
  ChatMessage({
    required this.Id,
    required this.chatId,
    required this.senderId,
    required this.encryptedContent,
    required this.sentAt,
  });

  @id
  int Id;
  final String chatId;
  final String senderId;
  final String encryptedContent;
  final DateTime sentAt;
}
