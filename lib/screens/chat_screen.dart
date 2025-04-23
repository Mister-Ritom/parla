import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:parla/auth/auth_provider.dart';
import 'package:parla/services/encryption_manager.dart';
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

  void _sendMessage() async {
    final message = _messageController.text.trim();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.nonNullUser.uid;

    if (message.isNotEmpty) {
      String? token = await TokenManager.getToken(widget.userId);
      if (token == null) {
        token = Uuid().v4();
        await TokenManager.saveToken(widget.userId, token);
      }
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
      batchWries.set(
        FirebaseFirestore.instance
            .collection('manifests')
            .doc(userId)
            .collection('userManifests')
            .doc(widget.userId),
        {'token': token, 'tokenSaved': true},
      );
      await batchWries.commit();
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final nonNullUser = authProvider.nonNullUser;
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
                  PopupMenuItem(value: 'report', child: Text('Report User')),
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

                final messages = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return FutureBuilder(
                      future: TokenManager.getToken(widget.userId),
                      builder: (context, tokenSnapshot) {
                        if (tokenSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (!tokenSnapshot.hasData) {
                          return Center(child: Text('Error retrieving token.'));
                        }
                        final token = tokenSnapshot.data!;
                        Map<String, String> data = {
                          'base64': message['message'],
                          'iv': message['iv'],
                        };
                        final decryptedMessage =
                            EncryptionManager.decryptFromBase64(data, token);
                        return ListTile(
                          title: Text(decryptedMessage),
                          subtitle: Text(
                            message['timestamp']?.toDate().toString() ??
                                'Unknown time',
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              // Handle delete message
                            },
                          ),
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
  }
}
