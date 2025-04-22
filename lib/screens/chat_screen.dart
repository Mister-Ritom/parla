import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ChatScreen extends StatefulWidget {
  final String userId;
  const ChatScreen({super.key, required this.userId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future:
          FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(child: Text('User not found'));
        }

        final userData = snapshot.data!;
        return Scaffold(
          appBar: AppBar(
            title: Text(userData['username']),
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
                    ],
                  );
                },
              ),
            ],

            backgroundColor: Colors.transparent,
          ),
          body: Column(children: []),
        );
      },
    );
  }
}
