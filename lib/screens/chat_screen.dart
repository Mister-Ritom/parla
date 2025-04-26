import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:parla/auth/auth_provider.dart';
import 'package:parla/services/encryption_manager.dart';
import 'package:parla/services/token_manager.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:visibility_detector/visibility_detector.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;

  const ChatScreen({super.key, required this.receiverId});

  @override
  State<StatefulWidget> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  late final String currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId =
        Provider.of<AuthProvider>(context, listen: false).nonNullUser.uid;
  }

  Future<String> createNewToken() async {
    final newToken = Uuid().v4();
    await FirebaseFirestore.instance
        .collection('chatManifest')
        .doc(widget.receiverId)
        .set({"token": newToken, "createdAt": FieldValue.serverTimestamp()});
    await TokenManager.saveToken(widget.receiverId, newToken);
    return newToken;
  }

  Future<String> setupToken() async {
    String? existingToken = await TokenManager.getToken(widget.receiverId);
    if (existingToken != null) {
      return existingToken;
    } else {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('chatManifest')
              .doc(currentUserId)
              .get();
      if (snapshot.exists && snapshot.data()?['token'] != null) {
        String? dataToken = snapshot.data()?['token'];
        if (dataToken != null) {
          await TokenManager.saveToken(currentUserId, dataToken);
          return dataToken;
        }
      } else {
        String newToken = await createNewToken();
        await TokenManager.saveToken(currentUserId, newToken);
      }
    }
    //If we reach here, it means we need to create a new token
    return await createNewToken();
  }

  Future<void> sendMessage(String token) async {
    final message = messageController.text.trim();
    if (message.isEmpty) return;

    final encrypted = EncryptionManager.encryptMessage(message, token!);
    final data = {
      'message': encrypted['base64'],
      'iv': encrypted['iv'],
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
      'senderId': currentUserId,
      'receiverId': widget.receiverId,
    };

    final userRef =
        FirebaseFirestore.instance
            .collection('messages')
            .doc(currentUserId)
            .collection('receivers')
            .doc(widget.receiverId)
            .collection('chat')
            .doc();

    final receiverRef =
        FirebaseFirestore.instance
            .collection('messages')
            .doc(widget.receiverId)
            .collection('receivers')
            .doc(currentUserId)
            .collection('chat')
            .doc();

    final batch = FirebaseFirestore.instance.batch();
    batch.set(userRef, data);
    batch.set(receiverRef, data);
    await batch.commit();

    messageController.clear();
    scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Widget buildMessageList(
    List<QueryDocumentSnapshot<Object?>> messages,
    String token,
  ) {
    return ListView.builder(
      reverse: true,
      controller: scrollController,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msgData = messages[index].data() as Map<String, dynamic>;
        final message = EncryptionManager.decryptFromBase64({
          'base64': msgData['message'],
          'iv': msgData['iv'],
        }, token);

        return VisibilityDetector(
          key: Key(messages[index].id),
          onVisibilityChanged: (info) {
            if (info.visibleFraction == 1.0 &&
                msgData['senderId'] != currentUserId) {
              final docRef = FirebaseFirestore.instance
                  .collection('messages')
                  .doc(currentUserId)
                  .collection('receivers')
                  .doc(widget.receiverId)
                  .collection('chat')
                  .doc(messages[index].id);
              docRef.update({'isRead': true});
            }
          },
          child: ListTile(
            title: Text(message),
            trailing: Icon(
              msgData['isRead']
                  ? FontAwesomeIcons.checkDouble
                  : FontAwesomeIcons.check,
              size: 16,
            ),
            subtitle: Text(msgData['timestamp']?.toDate().toString() ?? ''),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: setupToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error loading token'));
        } else {
          String token = snapshot.data as String;

          return Scaffold(
            appBar: AppBar(title: Text('Chat with ${widget.receiverId}')),
            body: Column(
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('messages')
                            .doc(currentUserId)
                            .collection('receivers')
                            .doc(widget.receiverId)
                            .collection('chat')
                            .orderBy('timestamp', descending: true)
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return buildMessageList(snapshot.data!.docs, token);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: messageController,
                          decoration: const InputDecoration(
                            hintText: 'Type a message...',
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => sendMessage(token),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () => sendMessage(token),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
