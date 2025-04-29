import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:parla/auth/auth_provider.dart' as local;
import 'package:parla/screens/chat_screen.dart';
import 'package:parla/screens/users/profile_screen.dart';
import 'package:parla/screens/users/search_screen.dart';
import 'package:parla/services/encryption_manager.dart';
import 'package:parla/services/token_manager.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final User user;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<local.AuthProvider>(
      context,
      listen: false,
    );
    user = authProvider.nonNullUser;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hello ${user.displayName}'),
        actions: [
          // Search button
          IconButton(
            icon: const Icon(FontAwesomeIcons.magnifyingGlass),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
          // Profile button (User's photo or default icon)
          IconButton(
            icon:
                user.photoURL == null
                    ? const Icon(Icons.person)
                    : CircleAvatar(
                      backgroundImage: NetworkImage(user.photoURL!),
                    ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(userId: user.uid),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream:
            FirebaseFirestore.instance
                .collection('messages')
                .doc(user.uid)
                .collection('receivers')
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No messages found.'));
          }

          final receiverIds = snapshot.data!.docs.map((doc) => doc.id).toList();

          return ListView.builder(
            itemCount: receiverIds.length,
            itemBuilder: (context, index) {
              final receiverId = receiverIds[index];
              return _buildReceiverTile(receiverId);
            },
          );
        },
      ),
    );
  }

  Widget _buildReceiverTile(String receiverId) {
    return StreamBuilder(
      stream:
          FirebaseFirestore.instance
              .collection('messages')
              .doc(user.uid)
              .collection('receivers')
              .doc(receiverId)
              .collection('chat')
              .orderBy('timestamp', descending: true)
              .limit(1)
              .snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (userSnapshot.hasError) {
          return Center(child: Text('Error: ${userSnapshot.error}'));
        }
        if (!userSnapshot.hasData || userSnapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final messageData = userSnapshot.data!.docs[0].data();
        return _buildUserInfo(receiverId, messageData);
      },
    );
  }

  Widget _buildUserInfo(String receiverId, Map<String, dynamic> messageData) {
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(receiverId).get(),
      builder: (context, userDocSnapshot) {
        if (userDocSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (userDocSnapshot.hasError) {
          return Center(child: Text('Error: ${userDocSnapshot.error}'));
        }
        if (!userDocSnapshot.hasData || userDocSnapshot.data == null) {
          return const SizedBox.shrink();
        }

        final userData = userDocSnapshot.data!.data() as Map<String, dynamic>;
        final encrypted = messageData['message'];
        final iv = messageData['iv'];
        final timestamp = messageData['timestamp'];
        return FutureBuilder<String?>(
          future: TokenManager.getToken(receiverId),
          builder: (context, tokenSnapshot) {
            if (tokenSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (tokenSnapshot.hasError) {
              return Center(child: Text('Error: ${tokenSnapshot.error}'));
            }
            if (!tokenSnapshot.hasData || tokenSnapshot.data == null) {
              return Center(child: Text('No token found for $receiverId'));
            }

            final token = tokenSnapshot.data!;
            final Map<String, String> data = {'base64': encrypted, 'iv': iv};
            final message = EncryptionManager.decryptFromBase64(data, token);

            return ListTile(
              title: Text(userData['name']),
              //subtitle is message with a maximum of 100 characters
              subtitle: Text(
                message.length > 100
                    ? '${message.substring(0, 100)}...'
                    : message,
              ),
              trailing: Text(
                '${timestamp?.toDate().hour}:${timestamp?.toDate().minute}',
              ),
              leading:
                  userData['photoUrl'] != null
                      ? CircleAvatar(
                        backgroundImage: NetworkImage(userData['photoUrl']),
                      )
                      : const Icon(Icons.person),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ChatScreen(
                          receiverId: receiverId,
                          receiverName: userData['name'],
                          receiverPhotoUrl: userData['photoUrl'],
                        ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
