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
  final String? receiverName;
  final String? receiverPhotoUrl;

  const ChatScreen({
    super.key,
    required this.receiverId,
    this.receiverName,
    this.receiverPhotoUrl,
  });

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
    final snapshot =
        await FirebaseFirestore.instance
            .collection('chatManifest')
            .doc(widget.receiverId)
            .get();
    String? existingToken = await TokenManager.getToken(widget.receiverId);
    if (existingToken != null) {
      if (!snapshot.exists) {
        // If the token exists but the firestore document doesn't, create a new one
        await FirebaseFirestore.instance
            .collection('chatManifest')
            .doc(widget.receiverId)
            .set({
              "token": existingToken,
              "createdAt": FieldValue.serverTimestamp(),
            });
      }
      return existingToken;
    } else {
      if (snapshot.exists && snapshot.data()?['token'] != null) {
        String? dataToken = snapshot.data()?['token'];
        if (dataToken != null) {
          await TokenManager.saveToken(widget.receiverId, dataToken);
          return dataToken;
        }
      } else {
        String newToken = await createNewToken();
        await TokenManager.saveToken(widget.receiverId, newToken);
      }
    }
    //If we reach here, it means we need to create a new token
    return await createNewToken();
  }

  Future<void> sendMessage(String token) async {
    final message = messageController.text.trim();
    if (message.isEmpty) return;

    final encrypted = EncryptionManager.encryptMessage(message, token);
    final data = {
      'message': encrypted['base64'],
      'iv': encrypted['iv'],
      'isRead': false,
      'timestamp': FieldValue.serverTimestamp(),
      'senderId': currentUserId,
      'receiverId': widget.receiverId,
    };

    final userRef = FirebaseFirestore.instance
        .collection('messages')
        .doc(currentUserId)
        .collection('receivers')
        .doc(widget.receiverId);

    final receiverRef = FirebaseFirestore.instance
        .collection('messages')
        .doc(widget.receiverId)
        .collection('receivers')
        .doc(currentUserId);

    final userChat = userRef.collection('chat').doc();
    final receiverChat = receiverRef.collection('chat').doc(userChat.id);

    final batch = FirebaseFirestore.instance.batch();
    // This is a preventive measure so firestore actully query the data
    final refData = await userRef.get();
    if (!refData.exists) {
      //If one exists then both should exist
      batch.set(userRef, {'createdAt': FieldValue.serverTimestamp()});
      batch.set(receiverRef, {'createdAt': FieldValue.serverTimestamp()});
    }

    batch.set(userChat, data);
    batch.set(receiverChat, data);
    await batch.commit();

    messageController.clear();
    scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Widget _buildChatBubble(String message, Map<String, dynamic> msgData) {
    final DateTime? timestamp = msgData['timestamp']?.toDate();
    final bool isRead = msgData['isRead'] as bool;
    final bool isCurrentUser = msgData['senderId'] == currentUserId;
    final Duration? timeDifference =
        timestamp != null ? DateTime.now().difference(timestamp) : null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment:
            CrossAxisAlignment.end, // Align text and read receipt
        children: [
          if (!isCurrentUser)
            widget.receiverPhotoUrl != null
                ? CircleAvatar(
                  backgroundImage: NetworkImage(widget.receiverPhotoUrl!),
                  radius: 20,
                )
                : Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Icon(FontAwesomeIcons.user, size: 22),
                ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isCurrentUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        isCurrentUser
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context).colorScheme.inversePrimary
                            : Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    message,
                    style: TextStyle(
                      color: isCurrentUser ? Colors.white : null,
                    ),
                  ),
                ),
                if (timeDifference != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      _formatTimeDifference(timeDifference),
                      style: TextStyle(color: Colors.grey[600], fontSize: 10),
                    ),
                  ),
              ],
            ),
          ),
          if (isCurrentUser)
            Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 3),
              child: Icon(
                isRead ? Icons.done_all : Icons.done,
                color: Theme.of(context).colorScheme.primary,
                size: 16,
              ),
            ),
        ],
      ),
    );
  }

  String _formatTimeDifference(Duration duration) {
    if (duration.inMinutes < 1) {
      return 'Just now';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes} min ago';
    } else if (duration.inHours < 24) {
      return '${duration.inHours} hour${duration.inHours == 1 ? '' : 's'} ago';
    } else {
      return '${duration.inDays} day${duration.inDays == 1 ? '' : 's'} ago';
    }
  }

  Widget _buildMessageInput(String token) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        // decoration stuff to make ti look like card
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Theme.of(context).dividerColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.link),
              onPressed: () {
                // Link action on the left
              },
            ),
            Container(
              width: 1,
              height: 40,
              color: Theme.of(context).dividerColor,
            ),
            Expanded(
              child: TextField(
                controller: messageController,
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  border: InputBorder.none, // Remove the underline
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 12,
                  ), // Adjust inner padding
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  sendMessage(token);
                },
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.mood, // Using Material Icons for closer resemblance
                  ),
                  onPressed: () {
                    // Emoji action
                  },
                ),
                SizedBox(width: 8), // Add some spacing
                IconButton(
                  icon: Icon(
                    Icons.mic, // Using Material Icons for closer resemblance
                  ),
                  onPressed: () {
                    // Voice action
                  },
                ),
              ],
            ),
          ],
        ),
      ),
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
          child: _buildChatBubble(message, msgData),
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
            appBar: AppBar(
              title: Text(
                'Chat with ${widget.receiverName ?? widget.receiverId}',
              ),
              elevation: 0,
              actions: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).highlightColor,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  margin: const EdgeInsets.only(right: 12),
                  child: IconButton(
                    icon: const Icon(FontAwesomeIcons.ellipsis),
                    onPressed: () {
                      // Handle the action when the icon is pressed
                      showModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                            ),
                            height: 200,
                            child: Column(
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.block),
                                  title: const Text('Block User'),
                                  onTap: () {
                                    // Handle block user action
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.report),
                                  title: const Text('Report User'),
                                  onTap: () {
                                    // Handle report user action
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
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
                            .limit(10)
                            .snapshots(),

                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return buildMessageList(snapshot.data!.docs, token);
                    },
                  ),
                ),
                _buildMessageInput(token),
              ],
            ),
          );
        }
      },
    );
  }
}
