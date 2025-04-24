import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  final String receiverId;

  const ChatScreen({Key? key, required this.receiverId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat with $receiverId')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: 20, // Example message count
              itemBuilder: (context, index) {
                return ListTile(title: Text('Message $index'));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    // Handle send message
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
