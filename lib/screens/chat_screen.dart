import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:parla/auth/auth_provider.dart';
import 'package:parla/models/chat_message.dart';
import 'package:parla/services/encryption_manager.dart';
import 'package:parla/services/isar_manager.dart';
import 'package:parla/services/token_manager.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class ChatScreen extends StatefulWidget {
  final String userId;
  final String username;
  const ChatScreen({super.key, required this.userId, required this.username});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  String token = '';
  final isarManager = IsarManager();

  Future<void> setupToken() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.nonNullUser.uid;
    //Check if the message was aved by the other user already
    await FirebaseFirestore.instance
        .collection('manifests')
        .doc(widget.userId)
        .collection('userManifests')
        .doc(userId)
        .get()
        .then((doc) {
          if (doc.exists) {
            final token = doc.data()?['token'];
            if (token != null) {
              TokenManager.saveToken(widget.userId, token);
              //Delete the document from Firestore
              FirebaseFirestore.instance
                  .collection('manifests')
                  .doc(widget.userId)
                  .collection('userManifests')
                  .doc(userId)
                  .delete();
            }
          }
        });
    if (token == '') {
      //Check if the token is already saved
      await TokenManager.getToken(widget.userId).then((value) {
        if (value != null) {
          token = value;
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    setupToken();
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.nonNullUser.uid;

    if (message.isNotEmpty) {
      final messageId = Uuid().v4();
      final encryptedMessage = EncryptionManager.encryptMessage(message, token);
      final messageData = {
        'messageId': messageId,
        'senderId': widget.userId,
        'message': encryptedMessage['base64'],
        'iv': encryptedMessage['iv'],
        'timestamp': FieldValue.serverTimestamp(),
      };
      final batchWries = FirebaseFirestore.instance.batch();
      batchWries.set(
        FirebaseFirestore.instance
            .collection('messages')
            .doc(userId)
            .collection('userMessages')
            .doc(widget.userId)
            .collection('chats')
            .doc(messageId),
        messageData,
      );
      if (token == '') {
        token = Uuid().v4();
        TokenManager.saveToken(widget.userId, token);
        batchWries.set(
          FirebaseFirestore.instance
              .collection('manifests')
              .doc(userId)
              .collection('userManifests')
              .doc(widget.userId),
          {'token': token, 'tokenSaved': true},
        );
      }
      await batchWries.commit();
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final nonNullUser = authProvider.nonNullUser;
    return FutureBuilder(
      future: isarManager.init(),
      builder: (context, snapshot) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.username),
            centerTitle: true,
            actions: [
              //Popup menu with icon ellipsis from font awesome
              IconButton(
                icon: Icon(FontAwesomeIcons.ellipsis),
                onPressed: () {
                  showMenu(
                    context: context,
                    position: RelativeRect.fromLTRB(100, 100, 0, 0),
                    items: [
                      PopupMenuItem(value: 'block', child: Text('Block User')),
                      PopupMenuItem(
                        value: 'report',
                        child: Text('Report User'),
                      ),
                      //clear chat
                      PopupMenuItem(
                        value: 'clear',
                        child: Text('Clear Chat'),
                        onTap: () async {
                          //Delete all from firestore using batches
                          final batch = FirebaseFirestore.instance.batch();
                          final messages =
                              await FirebaseFirestore.instance
                                  .collection('messages')
                                  .doc(nonNullUser.uid)
                                  .collection('userMessages')
                                  .doc(widget.userId)
                                  .collection('chats')
                                  .get();
                          for (final message in messages.docs) {
                            batch.delete(message.reference);
                          }
                          await batch.commit();
                          //Delete all from isar
                          await isarManager.deleteAllMessages(widget.userId);
                          setState(() {
                            //Refresh the screen
                            //This is not the best way to do it, but it works
                          });
                        },
                      ),
                    ],
                  );
                },
              ),
            ],

            backgroundColor: Colors.transparent,
          ),
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder(
                  stream:
                      FirebaseFirestore.instance
                          .collection('messages')
                          .doc(nonNullUser.uid)
                          .collection('userMessages')
                          .doc(widget.userId)
                          .collection('chats')
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Text('No messages yet.'));
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final messagesData =
                        snapshot.data!.docs.map((doc) => doc.data()).toList();

                    return FutureBuilder(
                      future: getCombinedMessages(messagesData),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(child: Text('No messages yet.'));
                        }

                        final messages = snapshot.data as List<ChatMessage>;
                        return ListView.builder(
                          reverse: true,
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final String decryptedMessage =
                                EncryptionManager.decryptFromBase64({
                                  'base64': message.encryptedContent,
                                  'iv': message.iv,
                                }, token);
                            return ListTile(
                              title: Text(decryptedMessage),
                              subtitle: Text(message.sentAt.toString()),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Type a message',
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.send),
                      onPressed: _sendMessage,
                    ),
                  ),
                  controller: _messageController,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<List<ChatMessage>> getCombinedMessages(
    List<Map<String, dynamic>> messages,
  ) async {
    for (final messageData in messages) {
      //Check if the message is already saved in the Isar database
      final isMessageSaved = isarManager.isMessageSaved(
        messageData['messageId'],
        widget.userId,
      );
      if (isMessageSaved) {
        //If the message is already saved, skip it
        continue;
      }
      final message = ChatMessage(
        iv: messageData['iv'],
        Id: 0, //Will be changed in the save function of manager
        chatId: messageData['messageId'],
        senderId: messageData['senderId'],
        encryptedContent: messageData['message'],
        sentAt: messageData['timestamp']?.toDate() ?? DateTime.now(),
      );
      await isarManager.saveMessage(message);
      //Delete the message from the Firestore
      await FirebaseFirestore.instance
          .collection('messages')
          .doc(messageData['senderId'])
          .collection('userMessages')
          .doc(widget.userId)
          .collection('chats')
          .doc(messageData['messageId'])
          .delete();
    }
    final messagesFromIsar = await isarManager.getMessagesFrom(widget.userId);
    return messagesFromIsar;
  }
}
